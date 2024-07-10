import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/recipe.dart';
import '../services/api_services/recipe_api_services.dart';

class RecipeController extends StateNotifier<AsyncValue<List<Recipe>>> {
  final ApiService apiService;

  RecipeController(this.apiService) : super(AsyncValue.loading());

  Future<void> fetchRecipes(String query) async {
    try {
      final recipes = await apiService.fetchRecipes(query);
      state = AsyncValue.data(recipes);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }
}
