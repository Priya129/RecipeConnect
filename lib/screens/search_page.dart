import 'package:flutter/material.dart';
import '../global/app_colors.dart';
import '../services/api_services/recipe_api_services.dart';
import '../widget/recipe_search_grid.dart';
import '../model/recipe.dart';
import '../widget/hower_button.dart';

class SearchPage extends StatefulWidget {
  final String initialQuery;

  const SearchPage({Key? key, this.initialQuery = ''}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  bool isLoading = false;
  TextEditingController searchController = TextEditingController();
  List<Recipe> searchResults = [];

  @override
  void initState() {
    super.initState();
    searchController.text = widget.initialQuery;
    if (widget.initialQuery.isNotEmpty) {
      fetchRecipes();
    }
  }

  Future<void> fetchRecipes() async {
    String query = searchController.text;
    setState(() {
      isLoading = true;
    });

    try {
      List<Recipe> recipes = await ApiService().fetchRecipes(query);
      setState(() {
        searchResults = recipes;
      });
    } catch (e) {
      print('Error: $e');
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isWideScreen = screenWidth > 600;

    return Scaffold(
      backgroundColor: AppColors.transparentColor,
      appBar: AppBar(
        leading: const BackButton(
          color: AppColors.mainColor,
        ),
        backgroundColor: Colors.white,
        title: const Text(
          'Search your Recipes',
          style: TextStyle(
            fontSize: 15,
            fontFamily: 'Poppins',
            color: AppColors.mainColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWideScreen ? 40.0 : 20.0,
                vertical: 20.0,
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.white,
                            ),
                            width: double.infinity,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 20.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: searchController,
                                      onSubmitted: (value) {
                                        fetchRecipes();
                                      },
                                      decoration: const InputDecoration(
                                        hintText: 'Search ',
                                        border: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: fetchRecipes,
                                    child: Center(
                                      child: Container(
                                        height: 40,
                                        width: 40,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(6),
                                          color: AppColors.mainColor,
                                        ),
                                        child: const Icon(
                                          Icons.search_rounded,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 20),
                        HoverIconButton(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: screenHeight,
              child: RecipeGrid(
                recipes: searchResults,
                isLoading: isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
