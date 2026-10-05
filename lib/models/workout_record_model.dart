class ActualSet {
  final int reps;
  final double weight;

  ActualSet({required this.reps, this.weight = 0.0});

  Map<String, dynamic> toMap() => {'reps': reps, 'weight': weight};

  factory ActualSet.fromMap(Map<String, dynamic> map) {
    return ActualSet(
      reps: (map['reps'] as num?)?.toInt() ?? 0,
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ExerciseRecord {
  final String exerciseId;
  final String exerciseName;
  final String muscleGroup;
  final int targetSets;
  final int targetReps;
  final List<ActualSet> actualSets;

  ExerciseRecord({
    required this.exerciseId,
    required this.exerciseName,
    this.muscleGroup = '',
    required this.targetSets,
    required this.targetReps,
    required this.actualSets,
  });

  int get targetTotal => targetSets * targetReps;
  int get actualTotal => actualSets.fold(0, (sum, s) => sum + s.reps);
  int get setsCompleted => actualSets.where((s) => s.reps > 0).length;

  double get completionPercent =>
      targetTotal == 0 ? 0 : ((actualTotal / targetTotal) * 100).clamp(0, 100);

  Map<String, dynamic> toMap() => {
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'muscleGroup': muscleGroup,
    'targetSets': targetSets,
    'targetReps': targetReps,
    'actualSets': actualSets.map((s) => s.toMap()).toList(),
  };

  factory ExerciseRecord.fromMap(Map<String, dynamic> map) {
    return ExerciseRecord(
      exerciseId: map['exerciseId'] ?? '',
      exerciseName: map['exerciseName'] ?? map['exerciseId'] ?? 'Exercise',
      muscleGroup: map['muscleGroup'] ?? '',
      targetSets: (map['targetSets'] as num?)?.toInt() ?? 0,
      targetReps: (map['targetReps'] as num?)?.toInt() ?? 0,
      actualSets: (map['actualSets'] as List<dynamic>? ?? [])
          .map((e) => ActualSet.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class WorkoutRecordModel {
  final String id;
  final String workoutPlanId;
  final String workoutPlanName;
  final DateTime date;
  final int durationMinutes;
  final List<ExerciseRecord> exerciseRecords;
  final String? notes;

  WorkoutRecordModel({
    required this.id,
    required this.workoutPlanId,
    this.workoutPlanName = 'Workout Session',
    required this.date,
    required this.durationMinutes,
    required this.exerciseRecords,
    this.notes,
  });

  int get totalExercises => exerciseRecords.length;

  int get totalSetsTarget =>
      exerciseRecords.fold(0, (sum, e) => sum + e.targetSets);

  int get totalSetsCompleted =>
      exerciseRecords.fold(0, (sum, e) => sum + e.setsCompleted);

  int get totalTargetReps =>
      exerciseRecords.fold(0, (sum, e) => sum + e.targetTotal);

  int get totalActualReps =>
      exerciseRecords.fold(0, (sum, e) => sum + e.actualTotal);

  double get overallCompletionPercent {
    if (totalTargetReps == 0) return 0;
    return ((totalActualReps / totalTargetReps) * 100).clamp(0, 100);
  }

  /// Total volume lifted in kilograms across all exercises and sets
  double get totalVolumeKg {
    double total = 0.0;
    for (final ex in exerciseRecords) {
      for (final s in ex.actualSets) {
        total += s.weight * s.reps;
      }
    }
    return total;
  }

  /// Estimated caloric expenditure based on session duration and volume
  int get estimatedCaloriesBurned {
    final base = durationMinutes * 6.0;
    final volumeBonus = (totalVolumeKg / 1000.0) * 12.0;
    return (base + volumeBonus).clamp(40.0, 1200.0).round();
  }

  /// Rule-based feedback according to document specification (Section 15):
  /// - Completion >= 90% -> "Excellent performance."
  /// - Completion 70-89% -> "Good progress. Keep working consistently."
  /// - Completion < 70%  -> "Try focusing on completing the prescribed sets."
  String get ruleBasedFeedback {
    final pct = overallCompletionPercent;
    if (pct >= 90.0) {
      return 'Excellent performance! You hit nearly all of your targets.';
    } else if (pct >= 70.0) {
      return 'Good progress. Keep working consistently to hit full reps.';
    } else {
      return 'Good effort! Try focusing on completing the prescribed sets next time.';
    }
  }

  Map<String, dynamic> toMap() => {
    'workoutPlanId': workoutPlanId,
    'workoutPlanName': workoutPlanName,
    'date': date.toIso8601String(),
    'durationMinutes': durationMinutes,
    'exerciseRecords': exerciseRecords.map((e) => e.toMap()).toList(),
    'totalTargetReps': totalTargetReps,
    'totalActualReps': totalActualReps,
    'completionPercentage': overallCompletionPercent,
    'feedback': ruleBasedFeedback,
    'notes': notes,
  };

  factory WorkoutRecordModel.fromMap(String id, Map<String, dynamic> map) {
    return WorkoutRecordModel(
      id: id,
      workoutPlanId: map['workoutPlanId'] ?? '',
      workoutPlanName: map['workoutPlanName'] ?? 'Workout Session',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 0,
      exerciseRecords: (map['exerciseRecords'] as List<dynamic>? ?? [])
          .map((e) => ExerciseRecord.fromMap(e as Map<String, dynamic>))
          .toList(),
      notes: map['notes'],
    );
  }
}
