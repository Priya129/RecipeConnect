import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/post_recipe_model.dart';

class RecipeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recipes'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('recipes').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No recipes found'));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final bool isWideScreen = constraints.maxWidth > 600;

              return ListView(
                children: snapshot.data!.docs.map((DocumentSnapshot doc) {
                  Recipe recipe = Recipe.fromFirestore(doc);
                  return Padding(
                    padding: EdgeInsets.all(isWideScreen ? 20.0 : 10.0),
                    child: Card(
                      elevation: 4,
                      child: ListTile(
                        contentPadding: EdgeInsets.all(isWideScreen ? 20.0 : 10.0),
                        title: Text(
                          recipe.name,
                          style: TextStyle(
                            fontSize: isWideScreen ? 20 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          recipe.description,
                          style: TextStyle(fontSize: isWideScreen ? 16 : 14),
                        ),
                        trailing: Text(
                          recipe.cuisine,
                          style: TextStyle(fontSize: isWideScreen ? 16 : 14),
                        ),
                        onTap: () {
                          // Navigate to a detailed recipe view
                        },
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
