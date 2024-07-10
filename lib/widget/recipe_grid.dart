import 'package:flutter/material.dart';
import '../shimmer/shimmer_recipe_card.dart';
import '../model/recipe.dart';
import '../view/recipe_view.dart';
import '../widget/recipe_card.dart';

class RecipesGrid extends StatelessWidget {
  final List<Recipe> recipes;
  final bool isLoading;

  const RecipesGrid({
    Key? key,
    required this.recipes,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: GridView.builder(
        scrollDirection: Axis.vertical,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 5.0,
          mainAxisSpacing: 10.0,
          childAspectRatio: 2 / 3,
        ),
        itemCount: isLoading ? 10 : recipes.length,
        itemBuilder: (context, index) {
          if (isLoading) {
            return RecipeCardSkeleton();
          } else {
          }
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecipeDetailPage(recipe: recipes[index]),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: RecipeCard(recipe: recipes[index]),
              ),
            ),
          );

        },
      ),
    );
  }
}

