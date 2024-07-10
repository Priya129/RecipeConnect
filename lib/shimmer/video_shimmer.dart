import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class VideoShimmer extends StatelessWidget {
  const VideoShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Stack(
        children: [
          Container(
            height: double.infinity,
            width: double.infinity,
            color: Colors.grey[300],
          ),
          Positioned(
            bottom: screenHeight * 0.03,
            left: screenWidth * 0.05,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      radius: screenWidth * 0.05,
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Container(
                      height: screenHeight * 0.025,
                      width: screenWidth * 0.25,
                      color: Colors.grey[300],
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.01),
                Container(
                  height: screenHeight * 0.025,
                  width: screenWidth * 0.5,
                  color: Colors.grey[300],
                ),
                SizedBox(height: screenHeight * 0.01),
                Container(
                  height: screenHeight * 0.025,
                  width: screenWidth * 0.15,
                  color: Colors.grey[300],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
