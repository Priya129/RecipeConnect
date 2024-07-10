import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../global/app_colors.dart';
import '../shimmer/video_shimmer.dart';
import '../screens/profile_screen.dart';

class VideoFeedScreen extends StatefulWidget {
  const VideoFeedScreen({super.key});

  @override
  VideoFeedScreenState createState() => VideoFeedScreenState();
}

class VideoFeedScreenState extends State<VideoFeedScreen> with WidgetsBindingObserver {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, ChewieController> _chewieControllers = {};
  final PageController _pageController = PageController();
  final Map<String, Duration> _videoPositions = {};
  final Map<String, bool> _videoPlayingStates = {};
  final Map<String, ValueNotifier<bool>> _isFollowingMap = {};
  final Map<String, ValueNotifier<int>> _likesCountMap = {};
  final Map<String, ValueNotifier<bool>> _isLikedMap = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    for (var controller in _chewieControllers.values) {
      controller.dispose();
    }
    _pageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<ChewieController> _initializeChewieController(String videoUrl, String postId) async {
    var fileInfo = await DefaultCacheManager().getFileFromCache(videoUrl);
    String localPath;

    if (fileInfo != null) {
      localPath = fileInfo.file.path;
    } else {
      var fetchedFile = await DefaultCacheManager().getSingleFile(videoUrl);
      localPath = fetchedFile.path;
    }

    var videoPlayerController = VideoPlayerController.file(File(localPath));
    await videoPlayerController.initialize();

    var position = _videoPositions[postId] ?? Duration.zero;
    var isPlaying = _videoPlayingStates[postId] ?? false;

    videoPlayerController.seekTo(position);
    if (isPlaying) {
      videoPlayerController.play();
    }

    return ChewieController(
      videoPlayerController: videoPlayerController,
      autoPlay: false,
      looping: false,
    );
  }

  Future<Map<String, dynamic>> _fetchUserProfile(String userId) async {
    var userDoc = await _firestore.collection('user').doc(userId).get();
    var currentUserId = _firebaseAuth.currentUser?.uid;
    var userProfile = userDoc.data() ?? {};
    bool isFollowing = userProfile['followers'].contains(currentUserId);
    _isFollowingMap[userId] = ValueNotifier(isFollowing);
    return userProfile;
  }

  void pauseAllVideos() {
    for (var postId in _chewieControllers.keys) {
      var controller = _chewieControllers[postId]!;
      if (controller.isPlaying) {
        _videoPositions[postId] = controller.videoPlayerController.value.position;
        _videoPlayingStates[postId] = true;
        controller.pause();
      } else {
        _videoPlayingStates[postId] = false;
      }
    }
  }

  Future<void> _followUnfollowUser(String followeeUid) async {
    String currentUserUid = _firebaseAuth.currentUser!.uid;
    try {
      await _firestore.runTransaction((transaction) async {
        DocumentReference currentUserRef = _firestore.collection('user').doc(currentUserUid);
        DocumentReference followeeRef = _firestore.collection('user').doc(followeeUid);

        DocumentSnapshot currentUserSnapshot = await transaction.get(currentUserRef);
        DocumentSnapshot followeeSnapshot = await transaction.get(followeeRef);

        if (!currentUserSnapshot.exists || !followeeSnapshot.exists) {
          throw Exception('User data not found');
        }

        List<String> currentFollowings = List<String>.from(currentUserSnapshot['followings']);
        List<String> followeeFollowers = List<String>.from(followeeSnapshot['followers']);

        if (currentFollowings.contains(followeeUid)) {
          currentFollowings.remove(followeeUid);
          followeeFollowers.remove(currentUserUid);
          _isFollowingMap[followeeUid]?.value = false;
        } else {
          currentFollowings.add(followeeUid);
          followeeFollowers.add(currentUserUid);
          _isFollowingMap[followeeUid]?.value = true;
        }

        transaction.update(currentUserRef, {'followings': currentFollowings});
        transaction.update(followeeRef, {'followers': followeeFollowers});
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error following/unfollowing user: $e')),
      );
    }
  }

  Future<void> _toggleLike(String postId) async {
    final currentUserId = _firebaseAuth.currentUser?.uid;
    if (currentUserId == null) return;
    final postRef = FirebaseFirestore.instance.collection('videos').doc(postId);
    final postSnapshot = await postRef.get();
    if (postSnapshot.exists) {
      List<String> likes = List<String>.from(postSnapshot.data()!['likes']);
      if (likes.contains(currentUserId)) {
        likes.remove(currentUserId);
        _isLikedMap[postId]?.value = false;
      } else {
        likes.add(currentUserId);
        _isLikedMap[postId]?.value = true;
      }
      _likesCountMap[postId]?.value = likes.length;
      await postRef.update({'likes': likes});
    }
  }

  Future<void> _confirmDeleteVideo(String postId, String videoUrl) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Video'),
          content: const Text('Are you sure you want to delete this video?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteVideo(postId, videoUrl);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteVideo(String postId, String videoUrl) async {
    try {
      await _firestore.collection('videos').doc(postId).delete();
      await FirebaseStorage.instance.refFromURL(videoUrl).delete();
      _chewieControllers.remove(postId)?.dispose();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting video: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Video Feed',
          style: TextStyle(fontSize: 15, fontFamily: 'Poppins'),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.mainColor,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.mainColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: StreamBuilder(
        stream: _firestore.collection('videos').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: VideoShimmer(),);
          }

          var videoDocs = snapshot.data!.docs;
          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: videoDocs.length,
            onPageChanged: (index) {
              pauseAllVideos();
            },
            itemBuilder: (context, index) {
              var videoData = videoDocs[index];
              var videoUrl = videoData['videoUrl'];
              var description = videoData['description'];
              var postId = videoData['postId'];
              var likes = List<String>.from(videoData['likes']);
              var userId = videoData['userId'];
              var currentUserId = _firebaseAuth.currentUser?.uid ?? '';

              if (!_likesCountMap.containsKey(postId)) {
                _likesCountMap[postId] = ValueNotifier(likes.length);
                _isLikedMap[postId] = ValueNotifier(likes.contains(currentUserId));
              }

              return FutureBuilder<ChewieController>(
                future: _chewieControllers.containsKey(postId)
                    ? Future.value(_chewieControllers[postId])
                    : _initializeChewieController(videoUrl, postId).then((controller) {
                  _chewieControllers[postId] = controller;
                  return controller;
                }),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    var chewieController = snapshot.data!;
                    return FutureBuilder<Map<String, dynamic>>(
                      future: _fetchUserProfile(userId),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState == ConnectionState.done) {
                          var userProfile = userSnapshot.data!;
                          bool isFollowing = _isFollowingMap[userId]?.value ?? false;
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfileScreen(
                                    userId: userId,
                                    currentUserId: currentUserId,
                                  ),
                                ),
                              );
                            },
                            child: Stack(
                              children: [
                                Center(
                                  child: Chewie(
                                    controller: chewieController,
                                  ),
                                ),
                                Positioned(
                                  bottom: screenHeight * 0.05,
                                  left: screenWidth * 0.05,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundImage: NetworkImage(userProfile['imageUrl']),
                                            radius: screenWidth * 0.05,
                                          ),
                                          SizedBox(width: screenWidth * 0.03),
                                          Text(
                                            userProfile['username'],
                                            style: const TextStyle(color: Colors.white, fontSize: 16),
                                          ),
                                          SizedBox(width: 10,),
                                          if (userId != currentUserId)
                                            ValueListenableBuilder<bool>(
                                              valueListenable: _isFollowingMap[userId]!,
                                              builder: (context, isFollowing, child) {
                                                return Container(
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: Colors.white),
                                                    borderRadius: BorderRadius.circular(8.0),
                                                  ),
                                                  child: TextButton(
                                                    onPressed: () => _followUnfollowUser(userId),
                                                    child: Text(
                                                      isFollowing ? 'Unfollow' : 'Follow',
                                                      style: const TextStyle(color: Colors.white),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          if (userId == currentUserId)
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline_sharp, color: Colors.white),
                                              onPressed: () => _confirmDeleteVideo(postId, videoUrl),
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: screenHeight * 0.01),
                                      Text(
                                        description,
                                        style: const TextStyle(color: Colors.white, fontSize: 16),
                                      ),
                                      Row(
                                        children: [
                                          ValueListenableBuilder<bool>(
                                            valueListenable: _isLikedMap[postId]!,
                                            builder: (context, isLiked, child) {
                                              return IconButton(
                                                icon: Icon(
                                                  isLiked ? Icons.favorite : Icons.favorite_border,
                                                  color: isLiked ? Colors.red : Colors.white,
                                                ),
                                                onPressed: () => _toggleLike(postId),
                                              );
                                            },
                                          ),
                                          ValueListenableBuilder<int>(
                                            valueListenable: _likesCountMap[postId]!,
                                            builder: (context, likesCount, child) {
                                              return Text(
                                                '$likesCount likes',
                                                style: const TextStyle(color: Colors.white),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return const Center(child: VideoShimmer());
                        }
                      },
                    );
                  } else {
                    return const Center(child: VideoShimmer());
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
