class ActualSet {
  final int reps;
  final double weight;

  ActualSet({required this.reps, this.weight = 0});

  Map<String, dynamic> toMap() => {'reps': reps, 'weight': weight};

  factory ActualSet.fromMap(Map<String, dynamic> map) {
    return ActualSet(
      reps: map['reps'] ?? 0,
      weight: (map['weight'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ExerciseRecord {
  final String exerciseId;
  final int targetSets;
  final int targetReps;
  final List<ActualSet> actualSets;

  ExerciseRecord({
    required this.exerciseId,
    required this.targetSets,
    required this.targetReps,
    required this.actualSets,
  });

  int get targetTotal => targetSets * targetReps;
  int get actualTotal => actualSets.fold(0, (sum, s) => sum + s.reps);
  double get completionPercent =>
      targetTotal == 0 ? 0 : (actualTotal / targetTotal) * 100;

  Map<String, dynamic> toMap() => {
    'exerciseId': exerciseId,
    'targetSets': targetSets,
    'targetReps': targetReps,
    'actualSets': actualSets.map((s) => s.toMap()).toList(),
  };

  factory ExerciseRecord.fromMap(Map<String, dynamic> map) {
    return ExerciseRecord(
      exerciseId: map['exerciseId'] ?? '',
      targetSets: map['targetSets'] ?? 0,
      targetReps: map['targetReps'] ?? 0,
      actualSets: (map['actualSets'] as List<dynamic>? ?? [])
          .map((e) => ActualSet.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class WorkoutRecordModel {
  final String id;
  final String workoutPlanId;
  final DateTime date;
  final int durationMinutes;
  final List<ExerciseRecord> exerciseRecords;
  final String? notes;

  WorkoutRecordModel({
    required this.id,
    required this.workoutPlanId,
    required this.date,
    required this.durationMinutes,
    required this.exerciseRecords,
    this.notes,
  });

  double get overallCompletionPercent {
    if (exerciseRecords.isEmpty) return 0;
    final total = exerciseRecords.fold<double>(
      0,
      (sum, e) => sum + e.completionPercent,
    );
    return total / exerciseRecords.length;
  }

  Map<String, dynamic> toMap() => {
    'workoutPlanId': workoutPlanId,
    'date': date.toIso8601String(),
    'durationMinutes': durationMinutes,
    'exerciseRecords': exerciseRecords.map((e) => e.toMap()).toList(),
    'notes': notes,
  };

  factory WorkoutRecordModel.fromMap(String id, Map<String, dynamic> map) {
    return WorkoutRecordModel(
      id: id,
      workoutPlanId: map['workoutPlanId'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      durationMinutes: map['durationMinutes'] ?? 0,
      exerciseRecords: (map['exerciseRecords'] as List<dynamic>? ?? [])
          .map((e) => ExerciseRecord.fromMap(e as Map<String, dynamic>))
          .toList(),
      notes: map['notes'],
    );
  }
}
