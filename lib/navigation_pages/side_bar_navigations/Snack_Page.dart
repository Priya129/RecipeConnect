import 'package:flutter/material.dart';
import '../../global/app_colors.dart';
import '../../services/api_services/recipe_api_services.dart';
import '../../widget/recipe_grid.dart';
import '../../model/recipe.dart';


class SnackPage extends StatefulWidget {
  const SnackPage({Key? key}) : super(key: key);

  @override
  State<SnackPage> createState() => _SnackPageState();
}

class _SnackPageState extends State<SnackPage> {
  List<Recipe> recipes = [];
  final ApiService apiService = ApiService();
  bool isLoading = false;
  @override
  void initState() {
    super.initState();
    fetchRecipes();
  }

  Future<void> fetchRecipes() async {
    setState(() {
      isLoading = true;
    });
    try {
      final fetchedRecipes = await apiService.fetchRecipes('snacks');
      setState(() {
        recipes = fetchedRecipes;
      });
    } catch (e) {
      print('Error fetching recipes: $e');
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 40.0, left: 30.0),
              child: RichText(
                text: const TextSpan(
                  text: 'Simply Recipe for ',
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Poppins',
                    fontSize: 18,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'Snacks',
                      style: TextStyle(
                        color: AppColors.mainColor,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: RecipesGrid(recipes: recipes,isLoading: isLoading,),
            ),
          ],
        ),
      ),
    );
  }
}
