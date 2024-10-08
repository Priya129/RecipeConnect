import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:like_button/like_button.dart';
import '../ad/ad_manager.dart';
import '../global/app_colors.dart';
import '../shimmer/shimmer_recipe_post.dart';
import 'comment_screen.dart';

class RecipePostScreen extends StatefulWidget {
  final String userId;

  const RecipePostScreen({super.key, required this.userId});

  @override
  State<RecipePostScreen> createState() => _RecipePostScreenState();
}

class _RecipePostScreenState extends State<RecipePostScreen> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final ValueNotifier<Map<String, bool>> showDetailsMap = ValueNotifier({});
  final AdManager adManager = AdManager();
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      adManager.initializeAds(context);
    });
  }

  Future<void> _fetchUserData() async {
    final userDoc = await FirebaseFirestore.instance.collection('user').doc(widget.userId).get();
    if (userDoc.exists) {
      setState(() {
        _userData = userDoc.data();
      });
    }
  }

  @override
  void dispose() {
    adManager.disposeAds();
    super.dispose();
  }

  Future<void> _toggleLike(String recipeId, List<dynamic> likes) async {
    final currentUserId = _firebaseAuth.currentUser?.uid;
    if (currentUserId == null) return;
    final recipeRef =
    FirebaseFirestore.instance.collection('recipes').doc(recipeId);
    if (likes.contains(currentUserId)) {
      likes.remove(currentUserId);
    } else {
      likes.add(currentUserId);
    }

    await recipeRef.update({'likes': likes});
  }

  Future<void> _deletePost(String recipeId) async {
    final currentUserId = _firebaseAuth.currentUser?.uid;
    final recipeRef =
    FirebaseFirestore.instance.collection('recipes').doc(recipeId);
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
            adManager.showInterstitialAd(context);
          },
        ),
        title: const Text(
          'Your Recipes',
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
      body: _userData == null
          ? Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('recipes')
                .where('userId', isEqualTo: widget.userId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: ShimmerRecipePost());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error fetching data'));
              }
              if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('No recipes found'));
              }

              final recipes = snapshot.data!.docs;

              return ListView.builder(
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  final recipeId = recipe.id;
                  final userId = recipe['userId'] as String?;
                  if (userId == null) {
                    return ListTile(
                      title: Text('Invalid recipe data'),
                    );
                  }
                  final profilePicUrl = _userData?['imageUrl'] ?? "https://via.placeholder.com/300";
                  final username = _userData?['username'] ?? "Unknown";
                  final likes = List<String>.from(recipe['likes'] ?? []);
                  final isLiked = currentUserId != null && likes.contains(currentUserId);

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
                              CachedNetworkImage(
                                imageUrl: recipe['imageUrl'] ??
                                    "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRDwmG52pVI5JZfn04j9gdtsd8pAGbqjjLswg&s",
                                height: 300,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              LikeButton(
                                onTap: (isLiked) async {
                                  _toggleLike(recipe.id, likes);
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
                                    size: 25,
                                    color: isLiked ? Colors.red : null,
                                  ),
                                  onPressed: () =>
                                      _toggleLike(recipe.id, likes),
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
                                                CommentSection(
                                                    recipeId: recipe.id),
                                          ),
                                    );
                                  },
                                  child: const ImageIcon(
                                    AssetImage('assets/Images/chat-bubble.png'),
                                    size: 20,
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
                            final showDetailsValue =
                                showDetails[recipeId] ?? false;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recipe['name'] ?? "Recipe Name",
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 5),
                                if (showDetailsValue)
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        recipe['description'] ??
                                            "No description",
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      const Text(
                                        "Ingredients:",
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      ...(recipe['subIngredients']
                                      as List<dynamic>? ??
                                          [])
                                          .map((ingredient) => Text(
                                          "• $ingredient",
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontFamily: 'Poppins')))
                                          .toList(),
                                      const SizedBox(height: 5),
                                    ],
                                  ),
                                GestureDetector(
                                  onTap: () {
                                    showDetailsMap.value = {
                                      ...showDetailsMap.value,
                                      recipeId: !showDetailsValue
                                    };
                                  },
                                  child: Text(
                                    showDetailsValue
                                        ? "Show less"
                                        : "Show more",
                                    style: const TextStyle(
                                      color: AppColors.mainColor,
                                      fontSize: 15,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ],
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
        ],
      ),
    );
  }
}
