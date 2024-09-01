import 'package:dio/dio.dart';
import '../../model/recipe.dart';

class ApiService {
  final Dio _dio = Dio();
  final String apiKey = '6b88d9fa10a904617623058b2e3247ed';
  final String apiId = '06fb9ba0';

  Future<List<Recipe>> fetchRecipes(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url =
          'https://api.edamam.com/search?q=$encodedQuery&app_id=$apiId&app_key=$apiKey';

      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        final jsonData = response.data;
        return (jsonData['hits'] as List)
            .map((hit) => Recipe.fromJson(hit['recipe']))
            .toList();
      } else {
        throw Exception('Failed to load recipes: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching recipes: $e');
      throw e;
    }
  }
}
