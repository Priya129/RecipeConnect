import 'package:flutter/material.dart';
import '../Firebase_services/favorite_service.dart';
import '../global/app_colors.dart';
import '../model/recipe.dart';

class RecipeCard extends StatefulWidget {
  final Recipe recipe;
  const RecipeCard({super.key, required this.recipe});

  @override
  RecipeCardState createState() => RecipeCardState();
}

class RecipeCardState extends State<RecipeCard> {
  final FavoritesService _favoritesService = FavoritesService();
  late Stream<List<String>> _favoritesStream;

  @override
  void initState() {
    super.initState();
    _favoritesStream = _favoritesService.getFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: _favoritesStream,
      builder: (context, snapshot) {
        bool isFavorite = snapshot.data?.contains(widget.recipe.id) ?? false;
        return Container(
          margin: const EdgeInsets.all(8.0),
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: Stack(
                    children: [
                      widget.recipe.image.isNotEmpty
                          ? Image.network(
                          widget.recipe.image,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                          : const Placeholder(
                        fallbackHeight: 120,
                        fallbackWidth: double.infinity,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                widget.recipe.label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 20,
                    width: 56,
                    decoration: BoxDecoration(
                      color: AppColors.mainColor,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child:  const Center(
                      child: Text(
                        "View Recipe",
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.deepOrange,
                      size: 15,
                    ),
                    onPressed: () {
                      _favoritesService.toggleFavorite(widget.recipe);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
