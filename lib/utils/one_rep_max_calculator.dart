/// Scientific 1-Rep Max (1RM) and Personal Record (PR) Calculator.
///
/// Implements standard exercise science formulas (Epley & Brzycki)
/// for compound and isolation strength movements.
class OneRepMaxCalculator {
  /// Calculates estimated 1-Rep Max using the Epley formula:
  /// 1RM = weight * (1 + reps / 30)
  static double calculate1RmEpley({
    required double weight,
    required int reps,
  }) {
    if (weight <= 0 || reps <= 0) return 0.0;
    if (reps == 1) return weight;
    final val = weight * (1.0 + (reps / 30.0));
    return double.parse(val.toStringAsFixed(1));
  }

  /// Calculates estimated 1-Rep Max using the Brzycki formula:
  /// 1RM = weight * (36 / (37 - reps))
  static double calculate1RmBrzycki({
    required double weight,
    required int reps,
  }) {
    if (weight <= 0 || reps <= 0) return 0.0;
    if (reps == 1) return weight;
    if (reps >= 37) return calculate1RmEpley(weight: weight, reps: reps);
    final val = weight * (36.0 / (37.0 - reps));
    return double.parse(val.toStringAsFixed(1));
  }

  /// Returns recommended primary estimated 1RM (blended standard).
  static double estimate1Rm({
    required double weight,
    required int reps,
  }) {
    return calculate1RmEpley(weight: weight, reps: reps);
  }

  /// Calculates total tonnage/volume for a set (weight * reps).
  static double calculateSetVolume({
    required double weight,
    required int reps,
  }) {
    if (weight <= 0 || reps <= 0) return 0.0;
    return weight * reps;
  }

  /// Checks if a completed set constitutes a New Personal Record (PR).
  ///
  /// Criteria for New PR:
  /// 1. Higher absolute weight lifted than previous best.
  /// 2. Higher estimated 1RM than previous best.
  static PrCheckResult checkPersonalRecord({
    required String exerciseId,
    required String exerciseName,
    required double weight,
    required int reps,
    double previousMaxWeight = 0.0,
    double previousEstimated1Rm = 0.0,
  }) {
    if (weight <= 0 || reps <= 0) {
      return PrCheckResult.noPr();
    }

    final newEst1Rm = estimate1Rm(weight: weight, reps: reps);
    bool isWeightPr = weight > previousMaxWeight && previousMaxWeight > 0;
    bool is1RmPr = newEst1Rm > previousEstimated1Rm && previousEstimated1Rm > 0;

    // First time logging with significant weight counts as baseline record
    bool isFirstRecord = previousMaxWeight == 0.0 && weight >= 20.0;

    if (isWeightPr || is1RmPr || isFirstRecord) {
      String reason;
      if (isFirstRecord) {
        reason = 'First benchmark recorded!';
      } else if (isWeightPr && is1RmPr) {
        final diff = (newEst1Rm - previousEstimated1Rm).toStringAsFixed(1);
        reason = 'New Max Weight & +$diff kg 1RM gain!';
      } else if (isWeightPr) {
        reason = 'Heaviest set logged (+${(weight - previousMaxWeight).toStringAsFixed(1)} kg)!';
      } else {
        final diff = (newEst1Rm - previousEstimated1Rm).toStringAsFixed(1);
        reason = 'Higher intensity rep endurance (+$diff kg 1RM)!';
      }

      return PrCheckResult(
        isPr: true,
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        weight: weight,
        reps: reps,
        estimated1Rm: newEst1Rm,
        previous1Rm: previousEstimated1Rm,
        reason: reason,
      );
    }

    return PrCheckResult.noPr();
  }
}

/// Result of evaluating a completed set for PR achievement.
class PrCheckResult {
  final bool isPr;
  final String exerciseId;
  final String exerciseName;
  final double weight;
  final int reps;
  final double estimated1Rm;
  final double previous1Rm;
  final String reason;

  const PrCheckResult({
    required this.isPr,
    this.exerciseId = '',
    this.exerciseName = '',
    this.weight = 0.0,
    this.reps = 0,
    this.estimated1Rm = 0.0,
    this.previous1Rm = 0.0,
    this.reason = '',
  });

  bool get isNewPr => isPr;
  double get newWeight => weight;
  int get newReps => reps;
  double get newEstimated1RM => estimated1Rm;
  double get previousEstimated1RM => previous1Rm;

  factory PrCheckResult.noPr() => const PrCheckResult(isPr: false);
}
