import 'package:flutter/material.dart';
import '../models/workout_model.dart';
import '../models/exercise_model.dart';
import '../models/workout_record_model.dart';
import '../services/firestore_service.dart';
import '../services/exercise_service.dart';
import '../utils/one_rep_max_calculator.dart';

class WorkoutProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final ExerciseService _exerciseService = ExerciseService();

  List<WorkoutPlanModel> _availablePlans = [];
  List<WorkoutPlanModel> _customPlans = [];
  List<WorkoutRecordModel> _workoutHistory = [];
  List<ExerciseModel> _muscleGroupExercises = [];
  bool _isLoading = false;
  bool _isMuscleLoading = false;
  String? _errorMessage;

  List<WorkoutPlanModel> get availablePlans => _availablePlans;
  List<WorkoutPlanModel> get customPlans => _customPlans;
  List<WorkoutRecordModel> get workoutHistory => _workoutHistory;
  List<ExerciseModel> get muscleGroupExercises => _muscleGroupExercises;
  bool get isLoading => _isLoading;
  bool get isMuscleLoading => _isMuscleLoading;
  String? get errorMessage => _errorMessage;

  // Active Workout State
  WorkoutPlanModel? _activePlan;
  List<ExerciseModel> _activeExercises = [];
  final Map<String, List<ActualSet>> _progress = {}; // exerciseId -> sets
  final List<PrCheckResult> _sessionPrs = [];
  List<PrCheckResult> _lastCompletedSessionPrs = [];
  DateTime? _startTime;
  WorkoutRecordModel? _lastCompletedWorkout;

  WorkoutPlanModel? get activePlan => _activePlan;
  List<ExerciseModel> get activeExercises => _activeExercises;
  DateTime? get startTime => _startTime;
  WorkoutRecordModel? get lastCompletedWorkout => _lastCompletedWorkout;
  List<PrCheckResult> get sessionPrs => List.unmodifiable(_sessionPrs);
  List<PrCheckResult> get lastCompletedSessionPrs =>
      List.unmodifiable(_lastCompletedSessionPrs);
  bool get isWorkoutInProgress => _activePlan != null && _startTime != null;

  int get activeElapsedSeconds {
    if (_startTime == null) return 0;
    return DateTime.now().difference(_startTime!).inSeconds;
  }

  int get totalActiveTargetReps {
    return _activeExercises.fold(
      0,
      (sum, e) => sum + (e.targetSets * e.targetReps),
    );
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

  double get totalActiveVolumeKg {
    double total = 0.0;
    for (final sets in _progress.values) {
      for (final s in sets) {
        total += s.weight * s.reps;
      }
    }
    return total;
  }

  double get currentCompletionPercent {
    if (totalActiveTargetReps == 0) return 0;
    return ((totalActiveActualReps / totalActiveTargetReps) * 100).clamp(
      0,
      100,
    );
  }

  /// Get historical max weight and estimated 1RM for an exercise across past workouts
  Map<String, double> getHistoricalBestForExercise(String exerciseId) {
    double maxWeight = 0.0;
    double max1Rm = 0.0;

    for (final workout in _workoutHistory) {
      for (final exRec in workout.exerciseRecords) {
        if (exRec.exerciseId == exerciseId ||
            exRec.exerciseName.toLowerCase().trim() ==
                exerciseId.toLowerCase().trim()) {
          for (final s in exRec.actualSets) {
            if (s.weight > maxWeight) maxWeight = s.weight;
            final est1Rm = OneRepMaxCalculator.estimate1Rm(
              weight: s.weight,
              reps: s.reps,
            );
            if (est1Rm > max1Rm) max1Rm = est1Rm;
          }
        }
      }
    }
    return {'maxWeight': maxWeight, 'max1Rm': max1Rm};
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

  Future<void> loadCustomPlans(String userId) async {
    try {
      _customPlans = await _firestoreService.getCustomWorkoutPlans(userId);
      notifyListeners();
    } catch (_) {
      // Keep existing custom plans on error
    }
  }

  Future<bool> saveCustomPlan(String userId, WorkoutPlanModel plan) async {
    final success = await _firestoreService.saveCustomWorkoutPlan(userId, plan);
    if (success) {
      _customPlans.removeWhere((p) => p.id == plan.id);
      _customPlans.insert(0, plan);
      notifyListeners();
    }
    return success;
  }

  Future<bool> deleteCustomPlan(String userId, String planId) async {
    final success = await _firestoreService.deleteCustomWorkoutPlan(userId, planId);
    if (success) {
      _customPlans.removeWhere((p) => p.id == planId);
      notifyListeners();
    }
    return success;
  }

  Future<void> loadExercisesForMuscle(String muscleGroup) async {
    _isMuscleLoading = true;
    notifyListeners();

    try {
      _muscleGroupExercises = await _exerciseService.getExercisesByMuscleGroup(
        muscleGroup,
      );
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

  Future<void> startCustomWorkout(
    String title,
    List<ExerciseModel> exercises,
  ) async {
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
      _activeExercises = await _firestoreService.getExercisesByIds(
        _activePlan!.exerciseIds,
      );
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

  PrCheckResult? addSet(String exerciseId, int reps, double weight) {
    if (!_progress.containsKey(exerciseId)) {
      _progress[exerciseId] = [];
    }
    _progress[exerciseId]!.add(ActualSet(reps: reps, weight: weight));

    PrCheckResult? prResult;
    if (weight > 0 && reps > 0) {
      final exercise = _activeExercises.firstWhere(
        (e) => e.id == exerciseId,
        orElse: () => ExerciseModel(
          id: exerciseId,
          name: 'Exercise',
          description: '',
          muscleGroup: '',
          difficulty: '',
          equipment: '',
          targetSets: 3,
          targetReps: 10,
          restSeconds: 60,
          instructions: '',
        ),
      );

      final historicalBest = getHistoricalBestForExercise(exerciseId);
      final check = OneRepMaxCalculator.checkPersonalRecord(
        exerciseId: exerciseId,
        exerciseName: exercise.displayName,
        weight: weight,
        reps: reps,
        previousMaxWeight: historicalBest['maxWeight'] ?? 0.0,
        previousEstimated1Rm: historicalBest['max1Rm'] ?? 0.0,
      );

      if (check.isPr) {
        _sessionPrs.add(check);
        prResult = check;
      }
    }

    notifyListeners();
    return prResult;
  }

  void removeLastSet(String exerciseId) {
    if (_progress.containsKey(exerciseId) &&
        _progress[exerciseId]!.isNotEmpty) {
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
    _sessionPrs.clear();
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
      _lastCompletedSessionPrs = List.from(_sessionPrs);
      _activePlan = null;
      _startTime = null;
      _activeExercises.clear();
      _progress.clear();
      _sessionPrs.clear();

      // Refresh history list
      loadHistory(userId);
      notifyListeners();
    }

    return success;
  }
}
