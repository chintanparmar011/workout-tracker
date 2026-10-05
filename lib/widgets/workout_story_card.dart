import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/workout_record_model.dart';
import '../models/running_session_model.dart';
import '../utils/one_rep_max_calculator.dart';

/// Aesthetic 9:16 Instagram/Social Story Card for OmniFit workouts & runs.
class WorkoutStoryCard extends StatelessWidget {
  final WorkoutRecordModel? workoutRecord;
  final List<PrCheckResult>? prs;
  final RunningSessionModel? runSession;

  const WorkoutStoryCard({
    super.key,
    this.workoutRecord,
    this.prs,
    this.runSession,
  });

  @override
  Widget build(BuildContext context) {
    final isStrength = workoutRecord != null;
    final title = isStrength
        ? (workoutRecord!.workoutPlanName.isNotEmpty
            ? workoutRecord!.workoutPlanName
            : 'Strength Session')
        : 'Outdoor Run';

    final date = isStrength
        ? workoutRecord!.date
        : (runSession?.startTime ?? DateTime.now());
    final dateStr = DateFormat('EEEE, MMM d • h:mm a').format(date);

    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F1117),
              Color(0xFF0B0C0E),
              Color(0xFF141722),
            ],
          ),
          border: Border.all(
            color: const Color(0xFFB4F000).withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB4F000).withValues(alpha: 0.12),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top OmniFit Brand Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB4F000),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.bolt,
                        color: Colors.black,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OMNIFIT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                        Text(
                          'ATHLETICS',
                          style: TextStyle(
                            color: Color(0xFFB4F000),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    isStrength ? 'STRENGTH' : 'CARDIO',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Workout Title & Timestamp
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 20),

            // 4-Grid Core Metrics
            if (isStrength) ...[
              _buildMetricGrid([
                _MetricItem(
                  label: 'VOLUME',
                  value:
                      '${workoutRecord!.totalVolumeKg.toStringAsFixed(0)} kg',
                  accent: const Color(0xFFB4F000),
                  icon: Icons.fitness_center,
                ),
                _MetricItem(
                  label: 'DURATION',
                  value: '${workoutRecord!.durationMinutes} min',
                  accent: Colors.white,
                  icon: Icons.timer_outlined,
                ),
                _MetricItem(
                  label: 'REPS COMPLETED',
                  value:
                      '${workoutRecord!.totalActualReps} / ${workoutRecord!.totalTargetReps}',
                  accent: Colors.white,
                  icon: Icons.check_circle_outline,
                ),
                _MetricItem(
                  label: 'BURN ESTIMATE',
                  value: '${workoutRecord!.estimatedCaloriesBurned} kcal',
                  accent: const Color(0xFFFF6B4A),
                  icon: Icons.local_fire_department,
                ),
              ]),
            ] else if (runSession != null) ...[
              _buildMetricGrid([
                _MetricItem(
                  label: 'DISTANCE',
                  value:
                      '${runSession!.distanceKm.toStringAsFixed(2)} km',
                  accent: const Color(0xFFB4F000),
                  icon: Icons.straighten,
                ),
                _MetricItem(
                  label: 'AVG PACE',
                  value: runSession!.averagePace,
                  accent: Colors.white,
                  icon: Icons.speed,
                ),
                _MetricItem(
                  label: 'DURATION',
                  value: _formatRunDuration(runSession!.durationSeconds),
                  accent: Colors.white,
                  icon: Icons.timer_outlined,
                ),
                _MetricItem(
                  label: 'ENERGY',
                  value: '${runSession!.calories} kcal',
                  accent: const Color(0xFFFF6B4A),
                  icon: Icons.local_fire_department,
                ),
              ]),
            ],

            const SizedBox(height: 16),

            // PR Milestone Banner or High-Energy Quote
            Expanded(
              child: _buildHighlightsSection(),
            ),

            const SizedBox(height: 12),

            // Bottom aesthetic footer
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bolt, color: Color(0xFFB4F000), size: 14),
                      SizedBox(width: 4),
                      Text(
                        'TRAINED WITH OMNIFIT',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '#NOEXCUSES',
                    style: TextStyle(
                      color: const Color(0xFFB4F000).withValues(alpha: 0.9),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricGrid(List<_MetricItem> items) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildMetricBox(items[0])),
            const SizedBox(width: 10),
            Expanded(child: _buildMetricBox(items[1])),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildMetricBox(items[2])),
            const SizedBox(width: 10),
            Expanded(child: _buildMetricBox(items[3])),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricBox(_MetricItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161922),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item.icon, size: 14, color: item.accent),
              const SizedBox(width: 5),
              Text(
                item.label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: item.accent,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightsSection() {
    final prList = prs ?? [];
    if (prList.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFD700).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('🏆', style: TextStyle(fontSize: 16)),
                SizedBox(width: 6),
                Text(
                  'NEW PERSONAL RECORDS',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: prList.length > 3 ? 3 : prList.length,
                separatorBuilder: (context, index) => const SizedBox(height: 6),
                itemBuilder: (context, idx) {
                  final pr = prList[idx];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            pr.exerciseName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '${pr.newWeight.toStringAsFixed(1)} kg × ${pr.newReps} (1RM: ${pr.newEstimated1RM.toStringAsFixed(1)}kg)',
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    // Default achievement highlight
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161922),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFB4F000).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bolt,
              color: Color(0xFFB4F000),
              size: 28,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'GOALS CRUSHED',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            workoutRecord?.ruleBasedFeedback ??
                'Consistency is what turns average into elite.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRunDuration(int seconds) {
    final mins = seconds ~/ 60;
    final remainingSecs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${remainingSecs.toString().padLeft(2, '0')}';
  }
}

class _MetricItem {
  final String label;
  final String value;
  final Color accent;
  final IconData icon;

  _MetricItem({
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
  });
}

/// Helper function to display the Story Card preview modal with sharing actions
void showWorkoutStoryModal(
  BuildContext context, {
  WorkoutRecordModel? workoutRecord,
  List<PrCheckResult>? prs,
  RunningSessionModel? runSession,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        height: MediaQuery.of(ctx).size.height * 0.90,
        decoration: const BoxDecoration(
          color: Color(0xFF0B0C0E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Share Workout Story',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 9:16 Card Preview
            Expanded(
              child: Center(
                child: WorkoutStoryCard(
                  workoutRecord: workoutRecord,
                  prs: prs,
                  runSession: runSession,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Share Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy Caption'),
                    onPressed: () {
                      _copySummaryToClipboard(
                        ctx,
                        workoutRecord: workoutRecord,
                        prs: prs,
                        runSession: runSession,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB4F000),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text(
                      'Share Story',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    onPressed: () {
                      _copySummaryToClipboard(
                        ctx,
                        workoutRecord: workoutRecord,
                        prs: prs,
                        runSession: runSession,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Workout caption copied to clipboard! Ready to share to Instagram & WhatsApp.',
                          ),
                          backgroundColor: Color(0xFF161922),
                        ),
                      );
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

void _copySummaryToClipboard(
  BuildContext context, {
  WorkoutRecordModel? workoutRecord,
  List<PrCheckResult>? prs,
  RunningSessionModel? runSession,
}) {
  HapticFeedback.lightImpact();
  final StringBuffer buffer = StringBuffer();

  if (workoutRecord != null) {
    buffer.writeln('⚡ OmniFit Workout Completed!');
    buffer.writeln('📋 ${workoutRecord.workoutPlanName}');
    buffer.writeln(
        '🏋️ Volume Lifted: ${workoutRecord.totalVolumeKg.toStringAsFixed(0)} kg');
    buffer.writeln('⏱️ Duration: ${workoutRecord.durationMinutes} mins');
    buffer.writeln('🔥 Burn: ~${workoutRecord.estimatedCaloriesBurned} kcal');
    if (prs != null && prs.isNotEmpty) {
      buffer.writeln('🏆 New PRs:');
      for (final p in prs) {
        buffer.writeln('  • ${p.exerciseName}: ${p.newWeight}kg x ${p.newReps}');
      }
    }
  } else if (runSession != null) {
    buffer.writeln('🏃 OmniFit Run Completed!');
    buffer.writeln('📍 Distance: ${runSession.distanceKm.toStringAsFixed(2)} km');
    buffer.writeln('⚡ Avg Pace: ${runSession.averagePace}');
    buffer.writeln('🔥 Calories: ${runSession.calories} kcal');
  }

  buffer.writeln('\n#OmniFit #TrainedWithOmniFit #FitnessGoals #PersonalRecord');

  Clipboard.setData(ClipboardData(text: buffer.toString()));
}
