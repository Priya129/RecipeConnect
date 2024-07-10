import 'package:cloud_firestore/cloud_firestore.dart';

class Recipe {
  final String id;
  final String name;
  final String description;
  final double cookingTime;
  final String cuisine;
  final List<String> subIngredients;
  final String calories;
  final String imageUrl;
  final Timestamp createdAt;

  Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.cookingTime,
    required this.cuisine,
    required this.subIngredients,
    required this.calories,
    required this.imageUrl,
    required this.createdAt,
  });

  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Recipe(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      cookingTime: (data['cookingTime'] ?? 0).toDouble(),
      cuisine: data['cuisine'] ?? '',
      subIngredients: List<String>.from(data['subIngredients'] ?? []),
      calories: data['calories'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}
