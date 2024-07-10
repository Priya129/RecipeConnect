import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class RecipeCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
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
            Container(
              height: 120,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 8.0),
            Container(
              height: 16,
              width: 120,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 8.0),
            Container(
              height: 14,
              width: 80,
              color: Colors.grey[300],
            ),
          ],
        ),
      ),
    );
  }
}