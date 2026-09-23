class WorkoutPlanModel {
  final String id;
  final String name;
  final String goal;
  final String fitnessLevel;
  final String muscleGroup;
  final String description;
  final List<String> exerciseIds;
  final int estimatedDuration; // in minutes

  WorkoutPlanModel({
    required this.id,
    required this.name,
    required this.goal,
    required this.fitnessLevel,
    required this.muscleGroup,
    required this.description,
    required this.exerciseIds,
    required this.estimatedDuration,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'goal': goal,
      'fitnessLevel': fitnessLevel,
      'muscleGroup': muscleGroup,
      'description': description,
      'exerciseIds': exerciseIds,
      'estimatedDuration': estimatedDuration,
    };
  }

  factory WorkoutPlanModel.fromMap(String id, Map<String, dynamic> map) {
    return WorkoutPlanModel(
      id: id,
      name: map['name'] ?? '',
      goal: map['goal'] ?? '',
      fitnessLevel: map['fitnessLevel'] ?? 'beginner',
      muscleGroup: map['muscleGroup'] ?? '',
      description: map['description'] ?? '',
      exerciseIds: List<String>.from(map['exerciseIds'] ?? []),
      estimatedDuration: map['estimatedDuration'] ?? 30,
    );
  }
}
