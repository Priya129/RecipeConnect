import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ingredient_model.dart';
import 'nutrient_model.dart';

class Recipe {
  final double yield;
  late final String id;
  final String label;
  final String uri;
  final String image;
  final double calories;
  final List<Ingredient> ingredients;
  final String url;
  final TotalNutrients? totalNutrients;

  Recipe({
    required this.yield,
    required this.uri,
    required this.label,
    required this.image,
    required this.ingredients,
    required this.calories,
    required this.url,
    this.totalNutrients,
  }) {
    id = generateIdFromUrl(uri);
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    var ingredientsJson = json['ingredients'] as List;
    List<Ingredient> ingredientsList = ingredientsJson.map((i) => Ingredient.fromJson(i)).toList();

    return Recipe(
      yield: json['yield'],
      label: json['label'],
      image: json['image'],
      calories: json['calories'],
      url: json['url'],
      uri: json['uri'],
      ingredients: ingredientsList,
      totalNutrients: json['totalNutrients'] != null
          ? TotalNutrients.fromJson(json['totalNutrients'])
          : null,
    );
  }

  factory Recipe.fromFirebase(DocumentSnapshot doc) {
    Map<String, dynamic> json = doc.data() as Map<String, dynamic>;
    return Recipe.fromJson(json);
  }

  Map<String, dynamic> toJson() {
    return {
      'yield':yield,
      'uid': FirebaseAuth.instance.currentUser?.uid,
      'uri': uri,
      'label': label,
      'image': image,
      'calories': calories,
      'url': url,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'totalNutrients': totalNutrients?.toJson(),
    };
  }

  String generateIdFromUrl(String uri) {
    if (uri.isNotEmpty) {
      if (uri.contains("recipe_")) {
        return uri.split("recipe_")[1];
      }
    }
    throw ArgumentError("Invalid recipe uri: $uri");
  }
}
