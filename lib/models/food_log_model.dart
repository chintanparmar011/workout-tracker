class FoodLogModel {
  final String id;
  final String foodId;
  final String foodName;
  final double quantity; // number of servings
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String mealType; // 'breakfast', 'lunch', 'dinner', 'snack'
  final DateTime date;

  FoodLogModel({
    required this.id,
    required this.foodId,
    required this.foodName,
    required this.quantity,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.mealType,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'foodId': foodId,
      'foodName': foodName,
      'quantity': quantity,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'mealType': mealType,
      'date': date.toIso8601String(),
    };
  }

  factory FoodLogModel.fromMap(String id, Map<String, dynamic> map) {
    return FoodLogModel(
      id: id,
      foodId: map['foodId'] ?? '',
      foodName: map['foodName'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
      mealType: map['mealType'] ?? 'snack',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
    );
  }
}
