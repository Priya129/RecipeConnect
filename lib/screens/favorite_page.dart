import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../global/app_colors.dart';
import '../navigation_pages/mainPage.dart';
import '../widget/recipe_grid.dart';
import '../model/recipe.dart';

class FavoritesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenHeight = screenSize.height;
    final double screenWidth = screenSize.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: (){
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => MainPage()),
            );
          },
            child: const Icon(Icons.keyboard_backspace,
                color: AppColors.mainColor)),
        backgroundColor: Colors.white,
        title: const Text(
          'Favorite Recipes',
          style: TextStyle(
            fontSize: 15,
            fontFamily: 'Poppins',
            color: AppColors.mainColor,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .collection('favorites')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No favorite recipes yet.'));
          } else {
            List<Recipe> favoriteRecipes = snapshot.data!.docs
                .map((doc) => Recipe.fromFirebase(doc))
                .toList();
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: screenHeight * 0.02,
              ),
              child: RecipesGrid(recipes: favoriteRecipes),
            );
          }
        },
      ),
    );
  }
}
