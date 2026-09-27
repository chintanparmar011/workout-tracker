import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/workout_provider.dart';
import '../../models/workout_record_model.dart';

class WorkoutSummaryScreen extends StatelessWidget {
  final WorkoutRecordModel? record;

  const WorkoutSummaryScreen({super.key, this.record});

  @override
  Widget build(BuildContext context) {
    final workoutProvider = context.watch<WorkoutProvider>();
    final summary = record ?? workoutProvider.lastCompletedWorkout;

    final duration = summary?.durationMinutes ?? 0;
    final exercisesCount = summary?.totalExercises ?? 0;
    final setsCompleted = summary?.totalSetsCompleted ?? 0;
    final setsTarget = summary?.totalSetsTarget ?? 0;
    final repsActual = summary?.totalActualReps ?? 0;
    final repsTarget = summary?.totalTargetReps ?? 0;
    final completionPct = summary?.overallCompletionPercent ?? 0.0;
    final feedback = summary?.ruleBasedFeedback ?? 'Great job completing your workout!';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Summary'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 72,
            ),
            const SizedBox(height: 16),
            Text(
              summary?.workoutPlanName.isNotEmpty == true
                  ? summary!.workoutPlanName
                  : 'Workout Completed!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Duration: $duration ${duration == 1 ? "min" : "mins"}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Rule-based Feedback Card (Section 15)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: completionPct >= 90
                    ? Colors.green.withValues(alpha: 0.1)
                    : (completionPct >= 70
                        ? Colors.orange.withValues(alpha: 0.1)
                        : Colors.blue.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: completionPct >= 90
                      ? Colors.green.withValues(alpha: 0.3)
                      : (completionPct >= 70
                          ? Colors.orange.withValues(alpha: 0.3)
                          : Colors.blue.withValues(alpha: 0.3)),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    completionPct >= 90
                        ? Icons.emoji_events
                        : (completionPct >= 70 ? Icons.thumb_up : Icons.fitness_center),
                    color: completionPct >= 90
                        ? Colors.green
                        : (completionPct >= 70 ? Colors.orange : Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      feedback,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Statistics Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: 'Exercises',
                    value: '$exercisesCount',
                    icon: Icons.list_alt,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Sets Done',
                    value: '$setsCompleted / $setsTarget',
                    icon: Icons.repeat,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: 'Total Reps',
                    value: '$repsActual / $repsTarget',
                    icon: Icons.fitness_center,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Completion',
                    value: '${completionPct.toStringAsFixed(1)}%',
                    icon: Icons.percent,
                    valueColor: completionPct >= 90 ? Colors.green : Colors.deepOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),

            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Training'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: Colors.deepOrange),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
