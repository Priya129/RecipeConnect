import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recipe_project/screens/recipepost_screen.dart';
import 'package:recipe_project/screens/userListScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ad/ad_manager.dart';
import '../screens/user_search_screen.dart';
import '../shimmer/shimmer_profile_screen.dart';
import '../Firebase_services/signin_screen.dart';
import '../global/app_colors.dart';
import '../shimmer/videoscreen.dart';
import 'chatscreen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  final String currentUserId;

  const ProfileScreen({
    Key? key,
    this.userId,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  late Future<DocumentSnapshot> userProfileFuture;
  bool isFollowing = false;
  List<String> userThumbnailVideos = [];
  List<String> userThumbnailPhotos = [];
  String? _username;
  String? _imageUrl;
  File? _pickedImageFile;
  int followers = 0;
  int followings = 0;
  final AdManager adManager = AdManager();

  @override
  void initState() {
    super.initState();
    userProfileFuture = _fetchUserProfile();
    _fetchUserVideosthumbnail();
    _fetchUserPostthumbnail();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      adManager.initializeAds(context);
    });
  }

  @override
  void dispose() {
    adManager.disposeAds();
    super.dispose();
  }

  Future<DocumentSnapshot> _fetchUserProfile() async {
    String uid = widget.userId ?? _auth.currentUser!.uid;
    DocumentSnapshot userProfile =
    await _firestore.collection('user').doc(uid).get();
    if (widget.userId != null) {
      DocumentSnapshot currentUserProfile =
      await _firestore.collection('user').doc(_auth.currentUser!.uid).get();
      List<String> followingsList =
      List<String>.from(currentUserProfile['followings']);
      setState(() {
        isFollowing = followingsList.contains(widget.userId);
      });
    }
    setState(() {
      followers = (userProfile['followers'] as List<dynamic>).length;
      followings = (userProfile['followings'] as List<dynamic>).length;
    });
    return userProfile;
  }

  Future<void> _fetchUserPostthumbnail() async {
    String uid = widget.userId ?? _auth.currentUser!.uid;
    QuerySnapshot querySnapshot = await _firestore
        .collection('recipes')
        .where('userId', isEqualTo: uid)
        .get();

    setState(() {
      userThumbnailPhotos =
          querySnapshot.docs.map((doc) => doc['imageUrl'] as String).toList();
    });
  }

  Future<void> _fetchUserVideosthumbnail() async {
    String uid = widget.userId ?? _auth.currentUser!.uid;
    QuerySnapshot querySnapshot = await _firestore
        .collection('videos')
        .where('userId', isEqualTo: uid)
        .get();

    setState(() {
      userThumbnailVideos = querySnapshot.docs
          .map((doc) => doc['thumbnailUrl'] as String)
          .toList();
    });
  }

  Future<void> _navigateToChat() async {
    if (widget.userId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            currentUserId: widget.currentUserId,
            otherUserId: widget.userId!,
          ),
        ),
      );
    }
  }

  Future<void> _followUnfollowUser(String followeeUid) async {
    String currentUserUid = _auth.currentUser!.uid;

    if (followeeUid == currentUserUid) {
      return;
    }

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
        setState(() {
          isFollowing = false;
          followers -= 1;
        });
      } else {
        currentFollowings.add(followeeUid);
        followeeFollowers.add(currentUserUid);
        setState(() {
          isFollowing = true;
          followers += 1;
        });
      }

      transaction.update(currentUserRef, {'followings': currentFollowings});
      transaction.update(followeeRef, {'followers': followeeFollowers});
    });
  }

  Future<void> _signOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await _auth.signOut();
    await _googleSignIn.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SignInScreen()),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedImageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    String uid = _auth.currentUser!.uid;

    if (_pickedImageFile != null) {
      final storageRef =
      FirebaseStorage.instance.ref().child('user_profiles/$uid.jpg');
      await storageRef.putFile(_pickedImageFile!);
      _imageUrl = await storageRef.getDownloadURL();
    }

    await _firestore.collection('user').doc(uid).update({
      'username': _username,
      'imageUrl': _imageUrl,
    }).then((_) {
      setState(() {
        userProfileFuture = _fetchUserProfile(); // Reload the profile data
      });
      Navigator.of(context).pop(); // Close the dialog
    }).catchError((error) {
      print("Error updating profile: $error");
    });
  }

  void _showEditProfileDialog(String currentUsername, String currentImageUrl) {
    _username = currentUsername;
    _imageUrl = currentImageUrl;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isLoading = false;

            return AlertDialog(
              title: const Center(
                child: Text(
                  'Edit Profile',
                  style: TextStyle(
                      color: AppColors.mainColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins'),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        height: 40,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.transparentColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: TextFormField(
                            initialValue: currentUsername,
                            decoration: const InputDecoration(
                                hintText: 'Username', border: InputBorder.none),
                            onChanged: (value) {
                              _username = value;
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _pickedImageFile != null
                        ? Image.file(_pickedImageFile!, height: 200, width: 200)
                        : currentImageUrl.isNotEmpty
                        ? Image.network(currentImageUrl,
                        height: 200, width: 200)
                        : Container(),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () async {
                        await _pickImage();
                        setState(() {});
                      },
                      child: Container(
                        height: 40,
                        width: 200,
                        decoration: BoxDecoration(
                          color: AppColors.mainColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                            child: Text(
                              'Change Profile Picture',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Poppins'),
                            )),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.mainColor,
                    ),
                  ),
                ),
                isLoading
                    ? const CircularProgressIndicator()
                    : GestureDetector(
                  onTap: () async {
                    setState(() {
                      isLoading = true;
                    });
                    await _updateProfile();
                    setState(() {
                      isLoading = false;
                    });
                  },
                  child: Container(
                    height: 30,
                    width: 60,
                    decoration: BoxDecoration(
                        color: AppColors.mainColor,
                        borderRadius: BorderRadius.circular(8)),
                    child: const Center(
                      child: Text(
                        'Save',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmSignOut() async {
    bool? signOutConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
    if (signOutConfirmed == true) {
      _signOut();
    }
  }

  Future<void> _refreshProfile() async {
    setState(() {
      userProfileFuture = _fetchUserProfile();
      _fetchUserVideosthumbnail();
      _fetchUserPostthumbnail();
    });
  }

  Widget buildColumn(int count, String label) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            adManager.showInterstitialAd(context);
          },
          color: AppColors.mainColor,
        ),
        title: const Text(
          "UserProfile",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            color: AppColors.mainColor,
          ),
        ),
        centerTitle: true,
        actions: [
          if (widget.userId != null && widget.userId != _auth.currentUser!.uid)
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline,
                  color: AppColors.mainColor),
              onPressed: _navigateToChat,
            ),
          IconButton(
            icon: const Icon(
              Icons.search,
              color: AppColors.mainColor,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchUserScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: AppColors.mainColor,
            ),
            onSelected: (String result) {
              if (result == 'Sign Out') {
                _confirmSignOut();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'Sign Out',
                child: Text('Sign Out'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: FutureBuilder<DocumentSnapshot>(
          future: userProfileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ShimmerProfileScreen();
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('User profile not found'));
            }
            var userData = snapshot.data!.data() as Map<String, dynamic>;
            var username = userData['username'] ?? 'Unknown';
            var email = userData['email'] ?? 'Unknown';
            var imageUrl = userData['imageUrl'] ?? '';
            var numPosts =
                userThumbnailPhotos.length + userThumbnailVideos.length;
            var followersList = List<String>.from(userData['followers']);
            var followingsList = List<String>.from(userData['followings']);

            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfileScreen(
                                    userId: widget.userId,
                                    currentUserId: widget.currentUserId,
                                  ),
                                ),
                              );
                            },
                            child: CircleAvatar(
                              radius: 46,
                              backgroundImage: NetworkImage(imageUrl),
                            ),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                buildColumn(numPosts, 'Post'),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => UserListScreen(
                                          userIds: followingsList,
                                          title: 'Following',
                                        ),
                                      ),
                                    );
                                  },
                                  child: buildColumn(followings, 'Followings'),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => UserListScreen(
                                          userIds: followersList,
                                          title: 'Followers',
                                        ),
                                      ),
                                    );
                                  },
                                  child: buildColumn(followers, 'Followers'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProfileScreen(
                                      userId: widget.userId,
                                      currentUserId: widget.currentUserId,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                username,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              email,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              height: 40,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.mainColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: widget.userId == null ||
                                    widget.userId == widget.currentUserId
                                    ? TextButton(
                                  onPressed: () => _showEditProfileDialog(
                                      username, imageUrl),
                                  child: const Text(
                                    'Edit Profile',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                )
                                    : TextButton(
                                  onPressed: () {
                                    _followUnfollowUser(
                                        widget.userId!);
                                  },
                                  child: Text(
                                    isFollowing
                                        ? 'Unfollow'
                                        : 'Follow',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight:
                                      FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Videos',
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                color: AppColors.mainColor,
                              ),
                            ),
                            const SizedBox(height: 10),
                            GridView.builder(
                              shrinkWrap: true,
                              physics:
                              const NeverScrollableScrollPhysics(),
                              gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 4.0,
                                mainAxisSpacing: 4.0,
                              ),
                              itemCount: userThumbnailVideos.length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            VideoFeedScreens(
                                              userId: widget.userId!,
                                            ),
                                      ),
                                    );
                                  },
                                  child: Stack(
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl:
                                        userThumbnailVideos[index],
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Icon(
                                          Icons
                                              .video_collection_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Photos',
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                color: AppColors.mainColor,
                              ),
                            ),
                            const SizedBox(height: 10),
                            GridView.builder(
                              shrinkWrap: true,
                              physics:
                              const NeverScrollableScrollPhysics(),
                              gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 4.0,
                                mainAxisSpacing: 4.0,
                              ),
                              itemCount: userThumbnailPhotos.length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            RecipePostScreen(
                                              userId: widget.userId!,
                                            ),
                                      ),
                                    );
                                  },
                                  child: Stack(
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl:
                                        userThumbnailPhotos[index],
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
