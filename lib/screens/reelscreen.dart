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
import '../routes/routes.dart';
import '../shimmer/video_shimmer.dart';
import '../screens/profile_screen.dart';

class ReelScreen extends StatefulWidget {
  const ReelScreen({super.key,
  });

  @override
  VideoFeedScreenState createState() => VideoFeedScreenState();
}

class VideoFeedScreenState extends State<ReelScreen>
    with WidgetsBindingObserver {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, ChewieController> _chewieControllers = {};
  final PageController _pageController = PageController();
  final Map<String, Duration> _videoPositions = {};
  final Map<String, bool> _videoPlayingStates = {};
  final Map<String, ValueNotifier<bool>> _isFollowingMap = {};
  final Map<String, ValueNotifier<List<String>>> _likesMap = {};
  final Map<String, Future<Map<String, dynamic>>> _userProfileCache = {};

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      pauseAllVideos();
    }
  }

  Future<ChewieController> _initializeChewieController(String videoUrl,
      String postId) async {
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

  Future<Map<String, dynamic>> _fetchUserProfile(String userId) {
    return _userProfileCache.putIfAbsent(userId, () async {
      var userDoc = await _firestore.collection('user').doc(userId).get();
      var currentUserId = _firebaseAuth.currentUser?.uid;
      var userProfile = userDoc.data() ?? {};
      bool isFollowing = userProfile['followers'].contains(currentUserId);
      _isFollowingMap[userId] = ValueNotifier(isFollowing);
      return userProfile;
    });
  }

  Future<List<String>> _fetchLikes(String postId) async {
    var videoDoc = await _firestore.collection('videos').doc(postId).get();
    return List<String>.from(videoDoc['likes']);
  }

  void pauseAllVideos() {
    for (var postId in _chewieControllers.keys) {
      var controller = _chewieControllers[postId]!;
      if (controller.isPlaying) {
        _videoPositions[postId] =
            controller.videoPlayerController.value.position;
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
        DocumentReference currentUserRef =
        _firestore.collection('user').doc(currentUserUid);
        DocumentReference followeeRef =
        _firestore.collection('user').doc(followeeUid);

        DocumentSnapshot currentUserSnapshot =
        await transaction.get(currentUserRef);
        DocumentSnapshot followeeSnapshot = await transaction.get(followeeRef);

        if (!currentUserSnapshot.exists || !followeeSnapshot.exists) {
          throw Exception('User data not found');
        }

        List<String> currentFollowings =
        List<String>.from(currentUserSnapshot['followings']);
        List<String> followeeFollowers =
        List<String>.from(followeeSnapshot['followers']);

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

  Future<void> _likeUnlikeVideo(String postId) async {
    String currentUserUid = _firebaseAuth.currentUser!.uid;
    try {
      await _firestore.runTransaction((transaction) async {
        DocumentReference videoRef =
        _firestore.collection('videos').doc(postId);
        DocumentSnapshot videoSnapshot = await transaction.get(videoRef);

        if (!videoSnapshot.exists) {
          throw Exception('Video not found');
        }

        List<String> likes = List<String>.from(videoSnapshot['likes']);
        bool isLiked = likes.contains(currentUserUid);

        if (isLiked) {
          likes.remove(currentUserUid);
        } else {
          likes.add(currentUserUid);
        }
        transaction.update(videoRef, {'likes': likes});

        // Directly update the ValueNotifier after transaction
        _likesMap[postId]?.value = likes;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error liking/unliking video: $e')),
      );
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
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;

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
            Routes().navigateToMainPage;
          },
        ),
      ),
      body: StreamBuilder(
        stream: _firestore
            .collection('videos')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const VideoShimmer();
          }
          var videoDocs = snapshot.data!.docs;
          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: (index) {
              pauseAllVideos();
            },
            itemBuilder: (context, index) {
              var videoDoc = videoDocs[index];
              var postId = videoDoc.id;
              var videoUrl = videoDoc['videoUrl'];
              var description = videoDoc['description'];
              var userId = videoDoc['userId'];
              var createdAt = videoDoc['createdAt'].toDate();
              var isCurrentUser = userId == _firebaseAuth.currentUser?.uid;

              return FutureBuilder<ChewieController>(
                future: _initializeChewieController(videoUrl, postId),
                builder: (context, chewieSnapshot) {
                  if (!chewieSnapshot.hasData) {
                    return const Center(child: VideoShimmer());
                  }
                  var chewieController = chewieSnapshot.data!;
                  _chewieControllers[postId] = chewieController;

                  return Stack(
                    children: [
                      Container(
                        width: screenWidth,
                        height: screenHeight,
                        child: Chewie(controller: chewieController),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 10,
                        right: 10,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              description,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontFamily: 'Poppins'),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                isCurrentUser
                                    ? FutureBuilder<Map<String, dynamic>>(
                                  future: _fetchUserProfile(userId),
                                  builder: (context, userProfileSnapshot) {
                                    if (!userProfileSnapshot.hasData) {
                                      return const CircularProgressIndicator();
                                    }
                                    var userProfile = userProfileSnapshot.data!;
                                    var profileImageUrl =
                                        userProfile['imageUrl'] ?? '';
                                    var username =
                                        userProfile['username'] ?? 'User';

                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  ProfileScreen(
                                                    userId: userId,
                                                    currentUserId:
                                                    _firebaseAuth
                                                        .currentUser!.uid,
                                                  )),
                                        );
                                      },
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundImage: profileImageUrl
                                                .isNotEmpty
                                                ? NetworkImage(profileImageUrl)
                                                : const AssetImage(
                                                'assets/default_profile.png')
                                            as ImageProvider,
                                            radius: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Center(
                                            child: Text(
                                              username,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontFamily: 'Poppins'),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.delete_outline_sharp, color: Colors.white),
                                            onPressed: () =>
                                                _confirmDeleteVideo(
                                                    postId, videoUrl),
                                          )
                                        ],
                                      ),
                                    );
                                  },
                                )
                                    : ValueListenableBuilder<bool>(
                                  valueListenable:
                                  _isFollowingMap[userId]!,
                                  builder: (context, isFollowing, child) {
                                    return GestureDetector(
                                      onTap: () =>
                                          _followUnfollowUser(userId),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4, horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: isFollowing
                                              ? Colors.white
                                              : Colors.transparent,
                                          border: Border.all(
                                              color: Colors.white),
                                          borderRadius:
                                          BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          isFollowing
                                              ? 'Following'
                                              : 'Follow',
                                          style: TextStyle(
                                            color: isFollowing
                                                ? AppColors.mainColor
                                                : Colors.white,
                                            fontSize: 12,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                FutureBuilder<List<String>>(
                                  future: _fetchLikes(postId),
                                  builder: (context, likesSnapshot) {
                                    if (likesSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      // Optionally show a loading indicator
                                    }

                                    if (likesSnapshot.hasData) {
                                      if (_likesMap[postId] == null) {
                                        _likesMap[postId] =
                                            ValueNotifier(likesSnapshot.data!);
                                      }

                                      return ValueListenableBuilder<
                                          List<String>>(
                                        valueListenable: _likesMap[postId]!,
                                        builder: (context, likes, child) {
                                          bool isLiked = likes.contains(
                                              _firebaseAuth.currentUser!.uid);

                                          return GestureDetector(
                                            onTap: () =>
                                                _likeUnlikeVideo(postId),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.favorite,
                                                  color: isLiked
                                                      ? Colors.red
                                                      : Colors.white,
                                                  size: 24,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${likes.length}',
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontFamily: 'Poppins'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    } else if (likesSnapshot.hasError) {
                                      return Text(
                                          'Error: ${likesSnapshot.error}');
                                    }

                                    return Text(
                                        'No likes'); // Default case if there's no data
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            itemCount: videoDocs.length,
          );
        },
      ),
    );
  }
}
