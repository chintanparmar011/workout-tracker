import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class OnboardingProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  // Personal info
  String? name;
  int? age;
  String? gender;
  double? height;
  double? currentWeight;

  // Goal + level
  String? fitnessGoal;
  String? fitnessLevel;
  List<String> targetMuscles = [];
  List<String> availableWorkoutDays = [];

  bool _isSaving = false;
  String? _errorMessage;

  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  void setPersonalInfo({
    required String name,
    required int age,
    required String gender,
    required double height,
    required double currentWeight,
  }) {
    this.name = name;
    this.age = age;
    this.gender = gender;
    this.height = height;
    this.currentWeight = currentWeight;
    notifyListeners();
  }

  void setFitnessGoal(String goal) {
    fitnessGoal = goal;
    notifyListeners();
  }

  void setFitnessLevel({
    required String level,
    required List<String> muscles,
    required List<String> days,
  }) {
    fitnessLevel = level;
    targetMuscles = muscles;
    availableWorkoutDays = days;
    notifyListeners();
  }

  Future<bool> submitOnboarding(String uid, String email) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final now = DateTime.now();
    final user = UserModel(
      uid: uid,
      name: name ?? '',
      email: email,
      age: age,
      gender: gender,
      height: height,
      currentWeight: currentWeight,
      fitnessLevel: fitnessLevel ?? 'beginner',
      fitnessGoal: fitnessGoal ?? 'improve_fitness',
      targetMuscles: targetMuscles,
      availableWorkoutDays: availableWorkoutDays,
      createdAt: now,
      updatedAt: now,
    );

    final result = await _firestoreService.saveUserProfile(user);

    _isSaving = false;
    if (!result.isSuccess) {
      _errorMessage = result.errorMessage;
    }
    notifyListeners();
    return result.isSuccess;
  }
}
