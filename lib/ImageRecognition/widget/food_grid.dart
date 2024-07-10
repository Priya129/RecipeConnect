import 'package:flutter/material.dart';

class FoodGrid extends StatelessWidget {
  final List<Map<String, dynamic>> recognizedFoods;

  const FoodGrid({required this.recognizedFoods});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10.0,
          crossAxisSpacing: 10.0,
        ),
        itemCount: recognizedFoods.length,
        itemBuilder: (context, index) {
          final food = recognizedFoods[index];
          final double probability = food['prob'];

          return Card(
            color: Colors.deepOrange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    food['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: LinearProgressIndicator(
                      value: probability,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text('Probability: ${(probability * 100).toStringAsFixed(2)}%'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
