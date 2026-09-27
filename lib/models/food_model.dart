class FoodModel {
  final String id; // USDA fdcId or unique ID
  final String name;
  final String servingSize;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String? brandOwner;

  FoodModel({
    required this.id,
    required this.name,
    required this.servingSize,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.brandOwner,
  });

  String get displayName {
    if (name.isEmpty) return 'Food Item';
    // USDA descriptions often have uppercase or commas e.g. "CHICKEN, BREAST, COOKED"
    final clean = name.toLowerCase().split(', ').reversed.join(' ');
    return clean
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  factory FoodModel.fromUsdaJson(Map<String, dynamic> json) {
    final nutrients = json['foodNutrients'] as List<dynamic>? ?? [];

    double findNutrient({
      required List<int> ids,
      required List<String> names,
    }) {
      for (final n in nutrients) {
        if (n is! Map<String, dynamic>) continue;
        final nutrientId = (n['nutrientId'] as num?)?.toInt() ?? 0;
        final nutrientName = (n['nutrientName'] ?? '').toString().toLowerCase();
        final unitName = (n['unitName'] ?? '').toString().toUpperCase();

        if (ids.contains(nutrientId)) {
          // If checking energy, make sure it's KCAL, not kJ
          if (ids.contains(1008) && unitName == 'KJ') continue;
          return (n['value'] as num?)?.toDouble() ?? 0.0;
        }

        for (final name in names) {
          if (nutrientName.contains(name.toLowerCase())) {
            if (name.toLowerCase() == 'energy' && unitName == 'KJ') continue;
            return (n['value'] as num?)?.toDouble() ?? 0.0;
          }
        }
      }
      return 0.0;
    }

    // Serving size format
    String serving = '100g';
    if (json['servingSize'] != null) {
      final size = (json['servingSize'] as num).toDouble();
      final unit = json['servingSizeUnit']?.toString() ?? 'g';
      serving = '${size.toStringAsFixed(size.truncateToDouble() == size ? 0 : 1)}$unit';
    } else if (json['householdServingFullText'] != null) {
      serving = json['householdServingFullText'].toString();
    }

    final rawDesc = json['description']?.toString() ?? 'Unknown Food';

    return FoodModel(
      id: json['fdcId']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: rawDesc,
      servingSize: serving,
      calories: findNutrient(ids: [1008, 208], names: ['Energy']),
      protein: findNutrient(ids: [1003, 203], names: ['Protein']),
      carbs: findNutrient(ids: [1005, 205], names: ['Carbohydrate']),
      fat: findNutrient(ids: [1004, 204], names: ['Total lipid', 'fat']),
      brandOwner: json['brandOwner']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'servingSize': servingSize,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'brandOwner': brandOwner,
  };

  factory FoodModel.fromMap(String id, Map<String, dynamic> map) {
    return FoodModel(
      id: id,
      name: map['name'] ?? '',
      servingSize: map['servingSize'] ?? '100g',
      calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
      brandOwner: map['brandOwner'],
    );
  }
}
