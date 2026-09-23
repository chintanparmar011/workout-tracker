import 'package:flutter/material.dart';
import '../models/workout_model.dart';
import '../models/exercise_model.dart';
import '../models/workout_record_model.dart';
import '../services/firestore_service.dart';

class WorkoutProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<WorkoutPlanModel> _availablePlans = [];
  List<WorkoutRecordModel> _workoutHistory = [];
  bool _isLoading = false;

  List<WorkoutPlanModel> get availablePlans => _availablePlans;
  List<WorkoutRecordModel> get workoutHistory => _workoutHistory;
  bool get isLoading => _isLoading;

  // Active Workout State
  WorkoutPlanModel? _activePlan;
  final List<ExerciseModel> _activeExercises = [];
  final Map<String, List<ActualSet>> _progress = {}; // exerciseId -> sets
  DateTime? _startTime;

  WorkoutPlanModel? get activePlan => _activePlan;
  List<ExerciseModel> get activeExercises => _activeExercises;
  DateTime? get startTime => _startTime;

  Future<void> loadPlans(String goal, String level) async {
    _isLoading = true;
    notifyListeners();

    _availablePlans = await _firestoreService.getWorkoutPlans(goal, level);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadHistory(String userId) async {
    _isLoading = true;
    notifyListeners();

    _workoutHistory = await _firestoreService.getWorkoutHistory(userId);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> startWorkout(WorkoutPlanModel plan) async {
    _activePlan = plan;
    _startTime = DateTime.now();
    _activeExercises.clear();
    _progress.clear();

    notifyListeners();
    await fetchExercisesForPlan();
  }

  // Fetch exercises for the selected plan
  Future<void> fetchExercisesForPlan() async {
    if (_activePlan == null) return;

    _isLoading = true;
    notifyListeners();

    _activeExercises.clear();
    for (String id in _activePlan!.exerciseIds) {
      final exercise = await _firestoreService.getExerciseById(id);
      if (exercise != null) {
        _activeExercises.add(exercise);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  void addSet(String exerciseId, int reps, double weight) {
    if (!_progress.containsKey(exerciseId)) {
      _progress[exerciseId] = [];
    }
    _progress[exerciseId]!.add(ActualSet(reps: reps, weight: weight));
    notifyListeners();
  }

  List<ActualSet> getSetsForExercise(String exerciseId) {
    return _progress[exerciseId] ?? [];
  }

  Future<bool> finishWorkout(String userId) async {
    if (_activePlan == null || _startTime == null) return false;

    final endTime = DateTime.now();
    final duration = endTime.difference(_startTime!).inMinutes;

    final List<ExerciseRecord> exerciseRecords = [];

    for (var exercise in _activeExercises) {
      final actualSets = _progress[exercise.id] ?? [];
      exerciseRecords.add(
        ExerciseRecord(
          exerciseId: exercise.id,
          targetSets: exercise.targetSets,
          targetReps: exercise.targetReps,
          actualSets: actualSets,
        ),
      );
    }

    final record = WorkoutRecordModel(
      id: '', // Firestore will generate
      workoutPlanId: _activePlan!.id,
      date: _startTime!,
      durationMinutes: duration,
      exerciseRecords: exerciseRecords,
    );

    final success = await _firestoreService.saveWorkoutRecord(userId, record);

    if (success) {
      _activePlan = null;
      _startTime = null;
      _activeExercises.clear();
      _progress.clear();
      notifyListeners();
    }

    return success;
  }
}
