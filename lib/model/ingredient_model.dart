class Ingredient {
  final String text;
  final double weight;

  Ingredient({
    required this.text,
    required this.weight,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      text: json['text'],
      weight: json['weight'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'weight': weight,
    };
  }
}
