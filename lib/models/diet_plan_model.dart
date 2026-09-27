class DietMeal {
  final String mealType; // 'breakfast', 'lunch', 'dinner', 'snack'
  final List<String> foods;
  final int estimatedCalories;
  final int estimatedProtein; // grams

  DietMeal({
    required this.mealType,
    required this.foods,
    required this.estimatedCalories,
    this.estimatedProtein = 0,
  });

  Map<String, dynamic> toMap() => {
    'mealType': mealType,
    'foods': foods,
    'estimatedCalories': estimatedCalories,
    'estimatedProtein': estimatedProtein,
  };

  factory DietMeal.fromMap(Map<String, dynamic> map) {
    return DietMeal(
      mealType: map['mealType'] ?? 'meal',
      foods: List<String>.from(map['foods'] ?? []),
      estimatedCalories: (map['estimatedCalories'] as num?)?.toInt() ?? 0,
      estimatedProtein: (map['estimatedProtein'] as num?)?.toInt() ?? 0,
    );
  }
}

class DietPlanModel {
  final String id;
  final String name;
  final String goal; // 'build_muscle', 'gain_weight', 'lose_weight', 'maintain_weight', 'improve_fitness'
  final String description;
  final List<DietMeal> meals;

  DietPlanModel({
    required this.id,
    required this.name,
    required this.goal,
    required this.description,
    required this.meals,
  });

  int get totalCalories => meals.fold(0, (sum, m) => sum + m.estimatedCalories);

  Map<String, dynamic> toMap() => {
    'name': name,
    'goal': goal,
    'description': description,
    'meals': meals.map((m) => m.toMap()).toList(),
  };

  factory DietPlanModel.fromMap(String id, Map<String, dynamic> map) {
    return DietPlanModel(
      id: id,
      name: map['name'] ?? '',
      goal: map['goal'] ?? '',
      description: map['description'] ?? '',
      meals: (map['meals'] as List<dynamic>? ?? [])
          .map((m) => DietMeal.fromMap(m as Map<String, dynamic>))
          .toList(),
    );
  }
}
