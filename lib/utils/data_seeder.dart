import 'package:cloud_firestore/cloud_firestore.dart';

class DataSeeder {
  static Future<void> seedInitialData() async {
    final db = FirebaseFirestore.instance;

    // Seed Exercises
    final exercises = [
      {
        'id': 'pushup01',
        'name': 'Push Ups',
        'muscleGroup': 'Chest',
        'difficulty': 'beginner',
        'equipment': 'none',
        'targetSets': 3,
        'targetReps': 15,
        'restSeconds': 60,
        'instructions':
            'Place hands slightly wider than shoulders. Lower body until chest nearly touches floor.',
        'isActive': true,
      },
      {
        'id': 'squat01',
        'name': 'Bodyweight Squats',
        'muscleGroup': 'Legs',
        'difficulty': 'beginner',
        'equipment': 'none',
        'targetSets': 3,
        'targetReps': 20,
        'restSeconds': 60,
        'instructions':
            'Stand with feet shoulder-width apart. Lower hips as if sitting in a chair.',
        'isActive': true,
      },
      {
        'id': 'plank01',
        'name': 'Plank',
        'muscleGroup': 'Abs/Core',
        'difficulty': 'beginner',
        'equipment': 'none',
        'targetSets': 3,
        'targetReps': 1, // 1 rep means 1 hold
        'restSeconds': 45,
        'instructions':
            'Hold push-up position but on forearms. Keep body in a straight line.',
        'isActive': true,
      },
    ];

    for (var ex in exercises) {
      final id = ex.remove('id') as String;
      await db.collection('exercises').doc(id).set(ex);
    }

    // Seed a Beginner Workout Plan
    await db.collection('workout_plans').doc('beginner_full_body').set({
      'name': 'Beginner Full Body',
      'goal': 'improve_fitness',
      'fitnessLevel': 'beginner',
      'muscleGroup': 'Full Body',
      'description':
          'A simple full-body workout for beginners to build foundational strength.',
      'exerciseIds': ['pushup01', 'squat01', 'plank01'],
      'estimatedDuration': 20,
    });

    // Seed a Chest specific plan
    await db.collection('workout_plans').doc('beginner_chest').set({
      'name': 'Basic Chest Routine',
      'goal': 'build_muscle',
      'fitnessLevel': 'beginner',
      'muscleGroup': 'Chest',
      'description': 'Target your chest muscles with these basic movements.',
      'exerciseIds': ['pushup01'],
      'estimatedDuration': 15,
    });
  }
}
