class UserModel {
  final String uid;
  final String name;
  final String email;
  final int? age;
  final String? gender;
  final double? height; // in cm
  final double? currentWeight; // in kg
  final String fitnessLevel; // beginner, intermediate, advanced
  final String fitnessGoal; // build_muscle, gain_weight, lose_weight, maintain_weight, improve_fitness
  final List<String> targetMuscles;
  final List<String> availableWorkoutDays;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.age,
    this.gender,
    this.height,
    this.currentWeight,
    this.fitnessLevel = 'beginner',
    this.fitnessGoal = 'improve_fitness',
    this.targetMuscles = const [],
    this.availableWorkoutDays = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'age': age,
      'gender': gender,
      'height': height,
      'currentWeight': currentWeight,
      'fitnessLevel': fitnessLevel,
      'fitnessGoal': fitnessGoal,
      'targetMuscles': targetMuscles,
      'availableWorkoutDays': availableWorkoutDays,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      age: map['age'],
      gender: map['gender'],
      height: (map['height'] as num?)?.toDouble(),
      currentWeight: (map['currentWeight'] as num?)?.toDouble(),
      fitnessLevel: map['fitnessLevel'] ?? 'beginner',
      fitnessGoal: map['fitnessGoal'] ?? 'improve_fitness',
      targetMuscles: List<String>.from(map['targetMuscles'] ?? []),
      availableWorkoutDays: List<String>.from(map['availableWorkoutDays'] ?? []),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  UserModel copyWith({
    String? name,
    int? age,
    String? gender,
    double? height,
    double? currentWeight,
    String? fitnessLevel,
    String? fitnessGoal,
    List<String>? targetMuscles,
    List<String>? availableWorkoutDays,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      currentWeight: currentWeight ?? this.currentWeight,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      targetMuscles: targetMuscles ?? this.targetMuscles,
      availableWorkoutDays: availableWorkoutDays ?? this.availableWorkoutDays,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}