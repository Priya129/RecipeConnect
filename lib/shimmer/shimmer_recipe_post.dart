import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerRecipePost extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isWideScreen = screenWidth > 600;

    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: EdgeInsets.all(isWideScreen ? 20.0 : 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: isWideScreen ? 20 : 17,
                  backgroundColor: Colors.grey[300],
                ),
                SizedBox(width: screenWidth * 0.03),
                Container(
                  width: screenWidth * 0.25,
                  height: screenHeight * 0.025,
                  color: Colors.grey[300],
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.02),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.grey[300],
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Container(
              width: screenWidth * 0.5,
              height: screenHeight * 0.015,
              color: Colors.grey[300],
            ),
            SizedBox(height: screenHeight * 0.01),
            Container(
              width: screenWidth * 0.4,
              height: screenHeight * 0.015,
              color: Colors.grey[300],
            ),
            SizedBox(height: screenHeight * 0.01),
            Container(
              width: screenWidth * 0.3,
              height: screenHeight * 0.015,
              color: Colors.grey[300],
            ),
            SizedBox(height: screenHeight * 0.02),
            Divider(
              color: Colors.grey[300],
              thickness: 1,
            ),
          ],
        ),
      ),
    );
  }
}
