import 'package:flutter/material.dart';

class NutrientRow extends StatelessWidget {
  final Color color;
  final String label;
  final num quantity;
  final String unit;

  NutrientRow({
    required this.color,
    required this.label,
    required this.quantity,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 5,
                  backgroundColor: color,
                ),
                SizedBox(width: 8),
                Text(label),
              ],
            ),
            Expanded(
              child: Container(), // This will take up the remaining space
            ),
            Text('${quantity.toString()} $unit'),
          ],
        ),
      ),
    );
  }
}
