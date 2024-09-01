import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:like_button/like_button.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import '../global/app_colors.dart';
import '../shimmer/video_shimmer.dart';
import 'comment_screen.dart';
import '../navigation_pages/mainPage.dart';

class VideoPost extends StatefulWidget {
  const VideoPost({super.key});

  @override
  State<VideoPost> createState() => _VideoPostState();
}

class _VideoPostState extends State<VideoPost> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final ValueNotifier<Map<String, bool>> showDetailsMap = ValueNotifier({});
  List<String> _followedUsers = [];
  Map<String, Map<String, dynamic>> _userDataCache = {};

  @override
  void initState() {
    super.initState();
    _getFollowedUsers();
    _fetchAllUserData();
  }

  Future<void> _getFollowedUsers() async {
    final currentUserId = _firebaseAuth.currentUser?.uid;
    if (currentUserId == null) return;
    final userDoc = await FirebaseFirestore.instance
        .collection('user')
        .doc(currentUserId)
        .get();
    final followedUsers =
    List<String>.from(userDoc.data()?['followings'] ?? []);
    setState(() {
      _followedUsers = followedUsers;
    });
  }

  Future<void> _fetchAllUserData() async {
    final querySnapshot =
    await FirebaseFirestore.instance.collection('user').get();
    final userDataCache = <String, Map<String, dynamic>>{};

    for (var doc in querySnapshot.docs) {
      userDataCache[doc.id] = doc.data() as Map<String, dynamic>;
    }

    setState(() {
      _userDataCache = userDataCache;
    });
  }

  Future<void> _toggleLike(String postId, List<dynamic> likes) async {
    final currentUserId = _firebaseAuth.currentUser?.uid;
    if (currentUserId == null) return;
    final recipeRef = FirebaseFirestore.instance.collection('videos').doc(postId);
    if (likes.contains(currentUserId)) {
      likes.remove(currentUserId);
    } else {
      likes.add(currentUserId);
    }

    await recipeRef.update({'likes': likes});
  }

  Future<void> _deletePost(String postId) async {
    final currentUserId = _firebaseAuth.currentUser?.uid;
    final recipeRef = FirebaseFirestore.instance.collection('videos').doc(postId);
    final recipeSnapshot = await recipeRef.get();

    if (recipeSnapshot.exists) {
      final recipeData = recipeSnapshot.data();
      final String? postUserId = recipeData?['userId'];

      if (currentUserId != null && postUserId == currentUserId) {
        bool confirmDelete = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Confirm Delete'),
            content: Text('Are you sure you want to delete this post?'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: Text('Delete'),
              ),
            ],
          ),
        );

        if (confirmDelete == true) {
          await recipeRef.delete();
        }
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Unauthorized'),
            content: Text('You are not authorized to delete this post.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _firebaseAuth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => MainPage()),
            );
          },
        ),
        title: const Text(
          'Your Recipes Reels',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.mainColor,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.mainColor),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('videos').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: VideoShimmer());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error fetching data'));
          }
          if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No recipes found'));
          }

          final recipesreels = snapshot.data!.docs.where((doc) {
            final userId = doc['userId'] as String?;
            return userId != null &&
                (_followedUsers.contains(userId) || userId == currentUserId);
          }).toList();

          return ListView.builder(
            itemCount: recipesreels.length,
            itemBuilder: (context, index) {
              final recipe = recipesreels[index];
              final userId = recipe['userId'] as String?;
              if (userId == null) {
                return ListTile(
                  title: Text('Invalid recipe data'),
                );
              }
              final userData = _userDataCache[userId];
              final profilePicUrl =
                  userData?['imageUrl'] ?? "https://via.placeholder.com/300";
              final username = userData?['username'] ?? "Unknown";
              final likes = List<String>.from(recipe['likes'] ?? []);
              final isLiked =
                  currentUserId != null && likes.contains(currentUserId);

              return Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 17,
                              backgroundImage: NetworkImage(profilePicUrl),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              username,
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                        if (userId == currentUserId)
                          PopupMenuButton(
                            icon: Icon(Icons.more_vert),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete Post'),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'delete') {
                                _deletePost(recipe.id);
                              }
                            },
                          ),
                      ],
                    ),
                    SizedBox(height: 10),
                    GestureDetector(
                      onDoubleTap: () {
                        _toggleLike(recipe.id, likes);
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: VideoPlayerWidget(
                                videoUrl: recipe['videoUrl'] ?? ""),
                          ),
                          LikeButton(
                            onTap: (isLiked) async {
                              await _toggleLike(recipe.id, likes);
                              return !isLiked;
                            },
                            isLiked: isLiked,
                            size: 80.0,
                            circleColor: const CircleColor(
                                start: Colors.red, end: Colors.redAccent),
                            bubblesColor: const BubblesColor(
                              dotPrimaryColor: Colors.red,
                              dotSecondaryColor: Colors.redAccent,
                            ),
                            likeBuilder: (bool isLiked) {
                              return Icon(
                                Icons.favorite,
                                color: isLiked
                                    ? Colors.transparent
                                    : Colors.transparent,
                                size: 80.0,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            IconButton(
                              icon: Icon(
                                isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 30,
                                color: isLiked ? Colors.red : null,
                              ),
                              onPressed: () => _toggleLike(recipe.id, likes),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (context) =>
                                      DraggableScrollableSheet(
                                        expand: false,
                                        initialChildSize: 0.8,
                                        minChildSize: 0.3,
                                        maxChildSize: 0.9,
                                        builder: (context, scrollController) =>
                                            CommentSection(recipeId: recipe.id),
                                      ),
                                );
                              },
                              child: const ImageIcon(
                                AssetImage('assets/Images/chat-bubble.png'),
                                size: 25,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text('${likes.length} likes'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ValueListenableBuilder<Map<String, bool>>(
                      valueListenable: showDetailsMap,
                      builder: (context, showDetails, child) {
                        return Text(
                          recipe['description'] ?? "Recipe Name",
                          style: const TextStyle(
                              fontSize: 15,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                    Divider(
                      color: Colors.grey.shade300,
                      thickness: 1,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),

    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  ChewieController? _chewieController;
  VideoPlayerController? _videoPlayerController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    if (widget.videoUrl.isEmpty) {
      print('Error: videoUrl is empty');
      return;
    }

    _videoPlayerController = VideoPlayerController.network(widget.videoUrl);

    try {
      await _videoPlayerController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: true,
      );
      setState(() {});
    } catch (e) {
      print('Error initializing video player: $e');
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chewieController == null || !_chewieController!.videoPlayerController.value.isInitialized) {
      return Center(child: VideoShimmer());
    }
    return Chewie(
      controller: _chewieController!,
    );
  }
}
