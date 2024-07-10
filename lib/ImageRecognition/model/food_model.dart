class FoodModel {
  final String name;
  final double probability;

  FoodModel({required this.name, required this.probability});

  factory FoodModel.fromJson(Map<String, dynamic> json) {
    return FoodModel(
      name: json['name'],
      probability: json['prob'],
    );
  }
}
