import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/weight_record_model.dart';
import '../services/firestore_service.dart';

class ProgressProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<WeightRecordModel> _weightHistory = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Aggregate workout metrics
  int _totalWorkouts = 0;
  int _totalSets = 0;
  int _totalReps = 0;
  double _avgCompletion = 0.0;

  List<WeightRecordModel> get weightHistory => _weightHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalWorkouts => _totalWorkouts;
  int get totalSets => _totalSets;
  int get totalReps => _totalReps;
  double get avgCompletion => _avgCompletion;

  double? get latestWeight =>
      _weightHistory.isNotEmpty ? _weightHistory.last.weight : null;

  double get weightChange {
    if (_weightHistory.length < 2) return 0.0;
    return _weightHistory.last.weight - _weightHistory.first.weight;
  }

  List<FlSpot> get weightChartSpots {
    if (_weightHistory.isEmpty) return [];
    return _weightHistory.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weight);
    }).toList();
  }

  Future<void> loadProgressData(String userId) async {
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      loadWeightHistory(userId, notify: false),
      loadWorkoutStats(userId, notify: false),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadWeightHistory(String userId, {bool notify = true}) async {
    try {
      _weightHistory = await _firestoreService.getWeightHistory(userId);
    } catch (_) {
      _weightHistory = [];
    }

    if (notify) {
      notifyListeners();
    }
  }

  Future<void> loadWorkoutStats(String userId, {bool notify = true}) async {
    try {
      final records = await _firestoreService.getWorkoutHistory(userId);
      _totalWorkouts = records.length;
      _totalSets = records.fold(0, (sum, r) => sum + r.totalSetsCompleted);
      _totalReps = records.fold(0, (sum, r) => sum + r.totalActualReps);

      if (records.isNotEmpty) {
        final totalPct = records.fold<double>(0.0, (sum, r) => sum + r.overallCompletionPercent);
        _avgCompletion = totalPct / records.length;
      } else {
        _avgCompletion = 0.0;
      }
    } catch (_) {
      // Keep existing stats on failure
    }

    if (notify) {
      notifyListeners();
    }
  }

  Future<bool> logWeight({
    required String userId,
    required double weight,
    DateTime? date,
    String? note,
  }) async {
    final record = WeightRecordModel(
      id: '',
      weight: weight,
      date: date ?? DateTime.now(),
      note: note,
    );

    // Optimistically update
    _weightHistory.add(record);
    _weightHistory.sort((a, b) => a.date.compareTo(b.date));
    notifyListeners();

    final success = await _firestoreService.saveWeightRecord(userId, record);
    if (!success) {
      _weightHistory.remove(record);
      notifyListeners();
      return false;
    }

    // Reload from server to synchronize
    loadWeightHistory(userId);
    return true;
  }
}
