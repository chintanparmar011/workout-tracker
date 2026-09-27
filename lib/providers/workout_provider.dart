import 'package:flutter/material.dart';
import '../models/workout_model.dart';
import '../models/exercise_model.dart';
import '../models/workout_record_model.dart';
import '../services/firestore_service.dart';
import '../services/exercise_service.dart';

class WorkoutProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final ExerciseService _exerciseService = ExerciseService();

  List<WorkoutPlanModel> _availablePlans = [];
  List<WorkoutRecordModel> _workoutHistory = [];
  List<ExerciseModel> _muscleGroupExercises = [];
  bool _isLoading = false;
  bool _isMuscleLoading = false;
  String? _errorMessage;

  List<WorkoutPlanModel> get availablePlans => _availablePlans;
  List<WorkoutRecordModel> get workoutHistory => _workoutHistory;
  List<ExerciseModel> get muscleGroupExercises => _muscleGroupExercises;
  bool get isLoading => _isLoading;
  bool get isMuscleLoading => _isMuscleLoading;
  String? get errorMessage => _errorMessage;

  // Active Workout State
  WorkoutPlanModel? _activePlan;
  List<ExerciseModel> _activeExercises = [];
  final Map<String, List<ActualSet>> _progress = {}; // exerciseId -> sets
  DateTime? _startTime;
  WorkoutRecordModel? _lastCompletedWorkout;

  WorkoutPlanModel? get activePlan => _activePlan;
  List<ExerciseModel> get activeExercises => _activeExercises;
  DateTime? get startTime => _startTime;
  WorkoutRecordModel? get lastCompletedWorkout => _lastCompletedWorkout;
  bool get isWorkoutInProgress => _activePlan != null && _startTime != null;

  int get activeElapsedSeconds {
    if (_startTime == null) return 0;
    return DateTime.now().difference(_startTime!).inSeconds;
  }

  int get totalActiveTargetReps {
    return _activeExercises.fold(0, (sum, e) => sum + (e.targetSets * e.targetReps));
  }

  int get totalActiveActualReps {
    int total = 0;
    for (final sets in _progress.values) {
      for (final s in sets) {
        total += s.reps;
      }
    }
    return total;
  }

  double get currentCompletionPercent {
    if (totalActiveTargetReps == 0) return 0;
    return ((totalActiveActualReps / totalActiveTargetReps) * 100).clamp(0, 100);
  }

  Future<void> loadPlans(String goal, String level) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _availablePlans = await _firestoreService.getWorkoutPlans(goal, level);
    } catch (e) {
      _errorMessage = 'Could not load workout plans';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _workoutHistory = await _firestoreService.getWorkoutHistory(userId);
    } catch (_) {
      // Keep existing list on failure
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadExercisesForMuscle(String muscleGroup) async {
    _isMuscleLoading = true;
    notifyListeners();

    try {
      _muscleGroupExercises = await _exerciseService.getExercisesByMuscleGroup(muscleGroup);
    } catch (_) {
      _muscleGroupExercises = [];
    } finally {
      _isMuscleLoading = false;
      notifyListeners();
    }
  }

  Future<void> startWorkout(WorkoutPlanModel plan) async {
    _activePlan = plan;
    _startTime = DateTime.now();
    _activeExercises = [];
    _progress.clear();
    _lastCompletedWorkout = null;

    notifyListeners();
    await fetchExercisesForPlan();
  }

  Future<void> startCustomWorkout(String title, List<ExerciseModel> exercises) async {
    _activePlan = WorkoutPlanModel(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: title,
      goal: 'custom',
      fitnessLevel: 'all',
      muscleGroup: 'Mixed',
      description: 'Custom training routine',
      exerciseIds: exercises.map((e) => e.id).toList(),
      estimatedDuration: 30,
    );
    _startTime = DateTime.now();
    _activeExercises = List.from(exercises);
    _progress.clear();
    _lastCompletedWorkout = null;
    notifyListeners();
  }

  Future<void> fetchExercisesForPlan() async {
    if (_activePlan == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _activeExercises = await _firestoreService.getExercisesByIds(_activePlan!.exerciseIds);
      // Fallback if none returned
      if (_activeExercises.isEmpty) {
        _activeExercises = _exerciseService
            .getAllCuratedExercises()
            .where((e) => _activePlan!.exerciseIds.contains(e.id))
            .toList();
      }
    } catch (_) {
      _activeExercises = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addSet(String exerciseId, int reps, double weight) {
    if (!_progress.containsKey(exerciseId)) {
      _progress[exerciseId] = [];
    }
    _progress[exerciseId]!.add(ActualSet(reps: reps, weight: weight));
    notifyListeners();
  }

  void removeLastSet(String exerciseId) {
    if (_progress.containsKey(exerciseId) && _progress[exerciseId]!.isNotEmpty) {
      _progress[exerciseId]!.removeLast();
      notifyListeners();
    }
  }

  List<ActualSet> getSetsForExercise(String exerciseId) {
    return _progress[exerciseId] ?? [];
  }

  void cancelActiveWorkout() {
    _activePlan = null;
    _startTime = null;
    _activeExercises.clear();
    _progress.clear();
    notifyListeners();
  }

  Future<bool> finishWorkout(String userId) async {
    if (_activePlan == null || _startTime == null) return false;

    final endTime = DateTime.now();
    final duration = endTime.difference(_startTime!).inMinutes;
    final effectiveDuration = duration == 0 ? 1 : duration;

    final List<ExerciseRecord> exerciseRecords = [];

    for (var exercise in _activeExercises) {
      final actualSets = _progress[exercise.id] ?? [];
      exerciseRecords.add(
        ExerciseRecord(
          exerciseId: exercise.id,
          exerciseName: exercise.displayName,
          muscleGroup: exercise.muscleGroup,
          targetSets: exercise.targetSets,
          targetReps: exercise.targetReps,
          actualSets: actualSets,
        ),
      );
    }

    final record = WorkoutRecordModel(
      id: '',
      workoutPlanId: _activePlan!.id,
      workoutPlanName: _activePlan!.name,
      date: _startTime!,
      durationMinutes: effectiveDuration,
      exerciseRecords: exerciseRecords,
    );

    final success = await _firestoreService.saveWorkoutRecord(userId, record);

    if (success) {
      _lastCompletedWorkout = record;
      _activePlan = null;
      _startTime = null;
      _activeExercises.clear();
      _progress.clear();

      // Refresh history list
      loadHistory(userId);
      notifyListeners();
    }

    return success;
  }
}
