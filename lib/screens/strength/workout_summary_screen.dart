import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/workout_provider.dart';
import '../../models/workout_record_model.dart';
import '../../widgets/workout_story_card.dart';

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
    final totalVolume = summary?.totalVolumeKg ?? 0.0;
    final calories = summary?.estimatedCaloriesBurned ?? 0;
    final feedback = summary?.ruleBasedFeedback ?? 'Great job completing your workout!';
    final prs = workoutProvider.lastCompletedSessionPrs;

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
              color: Color(0xFFB4F000),
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

            // PR Congratulations Banner (if any PRs were achieved)
            if (prs.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🏆', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          '${prs.length} NEW PERSONAL RECORD${prs.length > 1 ? "S" : ""}!',
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...prs.map((p) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            '• ${p.exerciseName}: ${p.newWeight.toStringAsFixed(1)} kg × ${p.newReps} (Est. 1RM: ${p.newEstimated1RM.toStringAsFixed(1)} kg)',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

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

            // Statistics Grid - Row 1
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    context,
                    label: 'Volume Lifted',
                    value: '${totalVolume.toStringAsFixed(0)} kg',
                    icon: Icons.fitness_center,
                    valueColor: const Color(0xFFB4F000),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    context,
                    label: 'Calories Burned',
                    value: '$calories kcal',
                    icon: Icons.local_fire_department,
                    valueColor: const Color(0xFFFF6B4A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Statistics Grid - Row 2
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    context,
                    label: 'Exercises',
                    value: '$exercisesCount',
                    icon: Icons.list_alt,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    context,
                    label: 'Sets Done',
                    value: '$setsCompleted / $setsTarget',
                    icon: Icons.repeat,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Statistics Grid - Row 3
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    context,
                    label: 'Total Reps',
                    value: '$repsActual / $repsTarget',
                    icon: Icons.check_circle_outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    context,
                    label: 'Completion',
                    value: '${completionPct.toStringAsFixed(1)}%',
                    icon: Icons.percent,
                    valueColor: completionPct >= 90 ? Colors.green : Colors.deepOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Share Story Card Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB4F000),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.auto_awesome, size: 20),
              label: const Text(
                'Share Story Card',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              onPressed: () {
                showWorkoutStoryModal(
                  context,
                  workoutRecord: summary,
                  prs: prs,
                );
              },
            ),
            const SizedBox(height: 12),

            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Training', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161922) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: valueColor ?? (isDark ? const Color(0xFFB4F000) : Colors.deepOrange)),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: valueColor ?? (isDark ? Colors.white : Colors.black87),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
