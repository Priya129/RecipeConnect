import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../ad/ad_manager.dart'; // Import the AdManager
import '../global/app_colors.dart';
import '../model/nutrient_info_model.dart';
import '../model/recipe.dart';
import '../navigation_pages/mainPage.dart';

class RecipeDetailPage extends StatelessWidget {
  final Recipe recipe;
  final AdManager _adManager = AdManager(); // Initialize the AdManager

  RecipeDetailPage({required this.recipe});

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blackColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                automaticallyImplyLeading: false,
                expandedHeight: 300.0,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: recipe.image.isNotEmpty
                      ? CachedNetworkImage(
                    imageUrl: recipe.image,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Placeholder(
                      fallbackHeight: 300.0,
                      fallbackWidth: double.infinity,
                    ),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  )
                      : const Placeholder(
                    fallbackHeight: 300.0,
                    fallbackWidth: double.infinity,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(34.0)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.blackColor,
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          recipe.label,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Calories: ${recipe.calories.toStringAsFixed(2)} kcal/${recipe.yield.toInt()} Servings',
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Ingredients:',
                          style: TextStyle(
                            fontSize: 20,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: recipe.ingredients.map((ingredient) {
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(right: 8.0),
                                    alignment: Alignment.topCenter,
                                    height: 9.0,
                                    width: 9.0,
                                    decoration: const BoxDecoration(
                                      color: Colors.black,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${ingredient.text} (${ingredient.weight.toStringAsFixed(2)}g)',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w100,
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Nutrients: ',
                          style: TextStyle(
                            fontSize: 20,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: 200,
                          decoration: BoxDecoration(
                            color: AppColors.transparentColor,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (recipe.totalNutrients?.pROCNT != null)
                                NutrientRow(
                                  color: Colors.green,
                                  label: recipe.totalNutrients!.pROCNT!.label!,
                                  quantity: num.parse(recipe.totalNutrients!.pROCNT!.quantity!.toStringAsFixed(2)),
                                  unit: recipe.totalNutrients!.pROCNT!.unit!,
                                ),
                              if (recipe.totalNutrients?.fAT != null)
                                NutrientRow(
                                  color: Colors.orange,
                                  label: recipe.totalNutrients!.fAT!.label!,
                                  quantity: num.parse(recipe.totalNutrients!.fAT!.quantity!.toStringAsFixed(2)),
                                  unit: recipe.totalNutrients!.fAT!.unit!,
                                ),
                              if (recipe.totalNutrients?.cHOCDF != null)
                                NutrientRow(
                                  color: Colors.red,
                                  label: recipe.totalNutrients!.cHOCDF!.label!,
                                  quantity: num.parse(recipe.totalNutrients!.cHOCDF!.quantity!.toStringAsFixed(2)),
                                  unit: recipe.totalNutrients!.cHOCDF!.unit!,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'For more information about the recipe:',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => _launchURL(recipe.url),
                          child: Text(
                            'Source: ${recipe.url}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => MainPage()),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _adManager.getLargeBannerAdWidget(), // Banner Ad at the bottom
    );
  }
}
