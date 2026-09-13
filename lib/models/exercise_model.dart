class ExerciseModel {
  final String id;
  final String name;
  final String description;
  final String muscleGroup;
  final String difficulty; // beginner, intermediate, advanced
  final String equipment;
  final int targetSets;
  final int targetReps;
  final int restSeconds;
  final String instructions;
  final String? imageUrl;
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
    this.isActive = true,
  });

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
      'isActive': isActive,
    };
  }

  factory ExerciseModel.fromMap(String id, Map<String, dynamic> map) {
    return ExerciseModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      muscleGroup: map['muscleGroup'] ?? '',
      difficulty: map['difficulty'] ?? 'beginner',
      equipment: map['equipment'] ?? 'none',
      targetSets: map['targetSets'] ?? 3,
      targetReps: map['targetReps'] ?? 10,
      restSeconds: map['restSeconds'] ?? 60,
      instructions: map['instructions'] ?? '',
      imageUrl: map['imageUrl'],
      isActive: map['isActive'] ?? true,
    );
  }

  factory ExerciseModel.fromExerciseDbJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: (json['instructions'] as List<dynamic>? ?? []).join(' '),
      muscleGroup: json['bodyPart'] ?? json['target'] ?? '',
      difficulty: 'beginner', // ExerciseDB doesn't provide this so default
      equipment: json['equipment'] ?? 'none',
      targetSets: 3, // ExerciseDB doesn't give sets/reps so set defaults
      targetReps: 12,
      restSeconds: 60,
      instructions: (json['instructions'] as List<dynamic>? ?? []).join(' '),
      imageUrl: json['gifUrl'],
      isActive: true,
    );
  }
}
