class ExerciseModel {
  final String id;
  final String name;
  final String description;
  final String muscleGroup; // Standardized: Chest, Back, Shoulders, Biceps, Triceps, Legs, Abs/Core
  final String difficulty; // beginner, intermediate, advanced
  final String equipment;
  final int targetSets;
  final int targetReps;
  final int restSeconds;
  final String instructions;
  final String? imageUrl;
  final String? bodyPart;
  final String? targetMuscle;
  final List<String> secondaryMuscles;
  final bool isActive;

  ExerciseModel({
    required this.id,
    required this.name,
    required this.description,
    required this.muscleGroup,
    required this.difficulty,
    required this.equipment,
    required this.targetSets,
    required this.targetReps,
    required this.restSeconds,
    required this.instructions,
    this.imageUrl,
    this.bodyPart,
    this.targetMuscle,
    this.secondaryMuscles = const [],
    this.isActive = true,
  });

  String get displayName {
    if (name.isEmpty) return 'Exercise';
    return name
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : '')
        .join(' ');
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'muscleGroup': muscleGroup,
      'difficulty': difficulty,
      'equipment': equipment,
      'targetSets': targetSets,
      'targetReps': targetReps,
      'restSeconds': restSeconds,
      'instructions': instructions,
      'imageUrl': imageUrl,
      'bodyPart': bodyPart,
      'targetMuscle': targetMuscle,
      'secondaryMuscles': secondaryMuscles,
      'isActive': isActive,
    };
  }

  factory ExerciseModel.fromMap(String id, Map<String, dynamic> map) {
    return ExerciseModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      muscleGroup: map['muscleGroup'] ?? 'General',
      difficulty: map['difficulty'] ?? 'beginner',
      equipment: map['equipment'] ?? 'none',
      targetSets: (map['targetSets'] as num?)?.toInt() ?? 3,
      targetReps: (map['targetReps'] as num?)?.toInt() ?? 10,
      restSeconds: (map['restSeconds'] as num?)?.toInt() ?? 60,
      instructions: map['instructions'] ?? '',
      imageUrl: map['imageUrl'],
      bodyPart: map['bodyPart'],
      targetMuscle: map['targetMuscle'],
      secondaryMuscles: List<String>.from(map['secondaryMuscles'] ?? []),
      isActive: map['isActive'] ?? true,
    );
  }

  factory ExerciseModel.fromExerciseDbJson(Map<String, dynamic> json) {
    final bodyPart = json['bodyPart']?.toString() ?? '';
    final target = json['target']?.toString() ?? '';
    final normalizedGroup = _normalizeMuscleGroup(bodyPart, target);

    String instructionsStr = '';
    if (json['instructions'] is List) {
      instructionsStr = (json['instructions'] as List<dynamic>).map((e) => e.toString()).join('\n');
    } else if (json['instructions'] != null) {
      instructionsStr = json['instructions'].toString();
    }

    final rawName = json['name']?.toString() ?? '';
    final formattedName = rawName
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');

    return ExerciseModel(
      id: json['id']?.toString() ?? '',
      name: formattedName.isNotEmpty ? formattedName : 'Exercise',
      description: 'Targeting $target with $bodyPart movements.',
      muscleGroup: normalizedGroup,
      difficulty: 'beginner',
      equipment: json['equipment']?.toString() ?? 'body weight',
      targetSets: 3,
      targetReps: 12,
      restSeconds: 60,
      instructions: instructionsStr,
      imageUrl: json['gifUrl']?.toString(),
      bodyPart: bodyPart,
      targetMuscle: target,
      secondaryMuscles: (json['secondaryMuscles'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      isActive: true,
    );
  }

  static String _normalizeMuscleGroup(String bodyPart, String target) {
    final bp = bodyPart.toLowerCase();
    final tg = target.toLowerCase();

    if (bp.contains('chest') || tg.contains('pectoral')) return 'Chest';
    if (bp.contains('back') || tg.contains('lats') || tg.contains('traps') || tg.contains('spine')) return 'Back';
    if (bp.contains('shoulder') || tg.contains('delts')) return 'Shoulders';
    if (tg.contains('biceps')) return 'Biceps';
    if (tg.contains('triceps')) return 'Triceps';
    if (bp.contains('arm')) {
      if (tg.contains('tricep')) return 'Triceps';
      return 'Biceps';
    }
    if (bp.contains('leg') || tg.contains('quad') || tg.contains('hamstring') || tg.contains('glute') || tg.contains('calve')) return 'Legs';
    if (bp.contains('waist') || tg.contains('abs') || tg.contains('core')) return 'Abs/Core';

    return 'Chest'; // Fallback
  }

  ExerciseModel copyWith({
    String? id,
    String? name,
    String? description,
    String? muscleGroup,
    String? difficulty,
    String? equipment,
    int? targetSets,
    int? targetReps,
    int? restSeconds,
    String? instructions,
    String? imageUrl,
    String? bodyPart,
    String? targetMuscle,
    List<String>? secondaryMuscles,
    bool? isActive,
  }) {
    return ExerciseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      difficulty: difficulty ?? this.difficulty,
      equipment: equipment ?? this.equipment,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      restSeconds: restSeconds ?? this.restSeconds,
      instructions: instructions ?? this.instructions,
      imageUrl: imageUrl ?? this.imageUrl,
      bodyPart: bodyPart ?? this.bodyPart,
      targetMuscle: targetMuscle ?? this.targetMuscle,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      isActive: isActive ?? this.isActive,
    );
  }
}
