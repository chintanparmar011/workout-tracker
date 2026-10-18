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
    final trimmed = name.trim();

    String toTitleCase(String text) {
      return text.split(' ').map((word) {
        if (word.isEmpty) return '';
        int firstLetterIdx = 0;
        while (firstLetterIdx < word.length &&
            !RegExp(r'[a-zA-Z]').hasMatch(word[firstLetterIdx])) {
          firstLetterIdx++;
        }
        if (firstLetterIdx >= word.length) return word;
        final prefix = word.substring(0, firstLetterIdx);
        final char = word[firstLetterIdx].toUpperCase();
        final rest = word.substring(firstLetterIdx + 1).toLowerCase();
        return '$prefix$char$rest';
      }).join(' ');
    }

    // Split by comma outside of parentheses
    final parts = <String>[];
    final buffer = StringBuffer();
    int depth = 0;
    for (int i = 0; i < trimmed.length; i++) {
      final char = trimmed[i];
      if (char == '(') depth++;
      if (char == ')') depth = (depth - 1).clamp(0, 99);
      if (char == ',' && depth == 0) {
        if (buffer.isNotEmpty) {
          parts.add(buffer.toString().trim());
          buffer.clear();
        }
      } else {
        buffer.write(char);
      }
    }
    if (buffer.isNotEmpty) {
      parts.add(buffer.toString().trim());
    }

    if (parts.length <= 1) {
      return toTitleCase(trimmed);
    }

    final mainPart =
        parts.take(parts.length > 2 ? 2 : 1).map(toTitleCase).join(' ');
    final subParts =
        parts.skip(parts.length > 2 ? 2 : 1).map(toTitleCase).join(', ');

    if (subParts.isNotEmpty && !subParts.startsWith('(')) {
      return '$mainPart ($subParts)';
    } else if (subParts.isNotEmpty) {
      return '$mainPart $subParts';
    }
    return mainPart;
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
