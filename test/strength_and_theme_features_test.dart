import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittracker/utils/one_rep_max_calculator.dart';
import 'package:fittracker/services/exercise_service.dart';
import 'package:fittracker/providers/theme_provider.dart';
import 'package:fittracker/models/workout_record_model.dart';

void main() {
  group('Scientific 1RM and PR Calculator Tests', () {
    test('estimate1Rm - 1 rep equals exact weight lifted', () {
      final oneRep = OneRepMaxCalculator.estimate1Rm(weight: 100.0, reps: 1);
      expect(oneRep, 100.0);
    });

    test('calculate1RmEpley - Epley formula calculation', () {
      // 100kg for 10 reps: 100 * (1 + 10/30) = 133.3 kg
      final epley = OneRepMaxCalculator.calculate1RmEpley(weight: 100.0, reps: 10);
      expect(epley, closeTo(133.3, 0.1));
    });

    test('calculate1RmBrzycki - Brzycki formula calculation', () {
      // 100kg for 5 reps: 100 * (36 / (37 - 5)) = 112.5 kg
      final brzycki = OneRepMaxCalculator.calculate1RmBrzycki(weight: 100.0, reps: 5);
      expect(brzycki, closeTo(112.5, 0.1));
    });

    test('calculateSetVolume - weights multiplied by reps', () {
      final vol = OneRepMaxCalculator.calculateSetVolume(
        weight: 80.0,
        reps: 8,
      );
      expect(vol, 640.0);
    });

    test('checkPersonalRecord - identifies new PR when weight exceeds past best', () {
      final result = OneRepMaxCalculator.checkPersonalRecord(
        exerciseId: 'bench-press',
        exerciseName: 'Barbell Bench Press',
        weight: 100.0,
        reps: 5,
        previousMaxWeight: 90.0,
        previousEstimated1Rm: 100.0,
      );

      expect(result.isNewPr, isTrue);
      expect(result.newWeight, 100.0);
      expect(result.newEstimated1RM, greaterThan(result.previousEstimated1RM));
    });

    test('checkPersonalRecord - no PR if weight and reps are below past best', () {
      final result = OneRepMaxCalculator.checkPersonalRecord(
        exerciseId: 'squat',
        exerciseName: 'Barbell Squat',
        weight: 80.0,
        reps: 5,
        previousMaxWeight: 100.0,
        previousEstimated1Rm: 120.0,
      );

      expect(result.isNewPr, isFalse);
    });
  });

  group('Curated Exercise Database Expansion Tests', () {
    test('getAllCuratedExercises returns over 60 exercises', () {
      final exercises = ExerciseService().getAllCuratedExercises();
      expect(exercises.length, greaterThanOrEqualTo(60));
    });

    test('Exercise library covers all major muscle categories including extensive Back library', () {
      final exercises = ExerciseService().getAllCuratedExercises();
      final backExercises = exercises.where((e) => e.muscleGroup.toLowerCase() == 'back').toList();
      final chestExercises = exercises.where((e) => e.muscleGroup.toLowerCase() == 'chest').toList();
      final legExercises = exercises.where((e) => e.muscleGroup.toLowerCase() == 'legs').toList();

      expect(backExercises.length, greaterThanOrEqualTo(10));
      expect(chestExercises.length, greaterThanOrEqualTo(8));
      expect(legExercises.length, greaterThanOrEqualTo(10));
    });
  });

  group('Workout Record Metrics Tests', () {
    test('totalVolumeKg calculates accurate total across all sets', () {
      final record = WorkoutRecordModel(
        id: 'test-rec',
        workoutPlanId: 'plan-1',
        workoutPlanName: 'Test Routine',
        date: DateTime.now(),
        durationMinutes: 45,
        exerciseRecords: [
          ExerciseRecord(
            exerciseId: 'ex1',
            exerciseName: 'Bench Press',
            targetSets: 3,
            targetReps: 10,
            actualSets: [
              ActualSet(reps: 10, weight: 60.0), // 600
              ActualSet(reps: 10, weight: 60.0), // 600
              ActualSet(reps: 8, weight: 70.0),  // 560
            ],
          ),
        ],
      );

      expect(record.totalVolumeKg, 1760.0);
      expect(record.estimatedCaloriesBurned, greaterThan(45 * 6));
    });
  });

  group('Theme Provider Tests', () {
    test('Defaults to dark mode', () {
      final themeProvider = ThemeProvider();
      expect(themeProvider.themeMode, ThemeMode.dark);
      expect(themeProvider.isDarkMode, isTrue);
    });

    test('toggleTheme toggles between light and dark', () {
      final themeProvider = ThemeProvider();
      themeProvider.toggleTheme(false);
      expect(themeProvider.themeMode, ThemeMode.light);
      expect(themeProvider.isDarkMode, isFalse);

      themeProvider.toggleTheme(true);
      expect(themeProvider.themeMode, ThemeMode.dark);
      expect(themeProvider.isDarkMode, isTrue);
    });
  });
}
