class FoodModel {
  final String id; // USDA fdcId
  final String name;
  final String servingSize;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  FoodModel({
    required this.id,
    required this.name,
    required this.servingSize,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory FoodModel.fromUsdaJson(Map<String, dynamic> json) {
    final nutrients = json['foodNutrients'] as List<dynamic>? ?? [];

    double getNutrient(String name) {
      final match = nutrients.firstWhere(
        (n) => n['nutrientName'] == name,
        orElse: () => null,
      );
      return match != null ? (match['value'] as num).toDouble() : 0.0;
    }

    return FoodModel(
      id: json['fdcId'].toString(),
      name: json['description'] ?? '',
      servingSize: '100g', // USDA data is typically per 100g
      calories: getNutrient('Energy'),
      protein: getNutrient('Protein'),
      carbs: getNutrient('Carbohydrate, by difference'),
      fat: getNutrient('Total lipid (fat)'),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'servingSize': servingSize,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
  };
}
