import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/running_provider.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  Future<void> _refresh() async {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      await Future.wait([
        context.read<ProgressProvider>().loadProgressData(user.uid),
        context.read<RunningProvider>().loadHistory(user.uid),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressProvider = context.watch<ProgressProvider>();
    final runningProvider = context.watch<RunningProvider>();
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Log Weight',
            onPressed: () => _openLogWeightDialog(context, user?.uid ?? ''),
          ),
        ],
      ),
      body: progressProvider.isLoading && progressProvider.weightHistory.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Weight Journey Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Weight Journey',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Log Weight'),
                        onPressed: () =>
                            _openLogWeightDialog(context, user?.uid ?? ''),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (progressProvider.latestWeight != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Current Weight',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      '${progressProvider.latestWeight!.toStringAsFixed(1)} kg',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                if (progressProvider.weightHistory.length >= 2)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: progressProvider.weightChange <= 0
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : Colors.orange.withValues(
                                              alpha: 0.1,
                                            ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${progressProvider.weightChange > 0 ? "+" : ""}${progressProvider.weightChange.toStringAsFixed(1)} kg',
                                      style: TextStyle(
                                        color:
                                            progressProvider.weightChange <= 0
                                                ? Colors.green
                                                : Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          const SizedBox(height: 16),

                          if (progressProvider.weightChartSpots.length < 2)
                            Container(
                              height: 160,
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.show_chart,
                                    size: 48,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    progressProvider.weightHistory.isEmpty
                                        ? 'No weight records yet.\nTap "Log Weight" to start tracking.'
                                        : 'Log at least 2 entries to view your weight progression curve.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            AspectRatio(
                              aspectRatio: 1.8,
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    getDrawingHorizontalLine: (val) => FlLine(
                                      color: Colors.grey[200]!,
                                      strokeWidth: 1,
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 36,
                                        getTitlesWidget: (val, meta) => Text(
                                          '${val.toInt()}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: 1,
                                        getTitlesWidget: (val, meta) {
                                          final idx = val.toInt();
                                          if (idx >= 0 &&
                                              idx <
                                                  progressProvider
                                                      .weightHistory
                                                      .length) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 6,
                                              ),
                                              child: Text(
                                                DateFormat('M/d').format(
                                                  progressProvider
                                                      .weightHistory[idx]
                                                      .date,
                                                ),
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 10,
                                                ),
                                              ),
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        },
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: progressProvider.weightChartSpots,
                                      isCurved: true,
                                      color: Colors.deepOrange,
                                      barWidth: 3,
                                      isStrokeCapRound: true,
                                      dotData: const FlDotData(show: true),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: Colors.deepOrange.withValues(
                                          alpha: 0.1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Real Strength & Workout Activity Stats
                  const Text(
                    'Strength Performance Summary',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatTile(
                          label: 'Workouts',
                          value: '${progressProvider.totalWorkouts}',
                          icon: Icons.fitness_center,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatTile(
                          label: 'Sets Completed',
                          value: '${progressProvider.totalSets}',
                          icon: Icons.repeat,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatTile(
                          label: 'Total Repetitions',
                          value: '${progressProvider.totalReps}',
                          icon: Icons.bolt,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatTile(
                          label: 'Avg Completion',
                          value:
                              '${progressProvider.avgCompletion.toStringAsFixed(0)}%',
                          icon: Icons.check_circle_outline,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Real Running Performance Summary
                  const Text(
                    'Running Performance Summary',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatTile(
                          label: 'Total Running Distance',
                          value: '${runningProvider.totalDistanceKm.toStringAsFixed(1)} km',
                          icon: Icons.straighten,
                          color: Colors.lightBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatTile(
                          label: 'Number of Runs',
                          value: '${runningProvider.totalRuns}',
                          icon: Icons.directions_run,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatTile(
                          label: 'Best Pace',
                          value: runningProvider.bestPace,
                          icon: Icons.speed,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatTile(
                          label: 'Longest Run',
                          value: '${runningProvider.longestRunKm.toStringAsFixed(1)} km',
                          icon: Icons.emoji_events,
                          color: Colors.amber[800]!,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildStatTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  void _openLogWeightDialog(BuildContext context, String userId) {
    if (userId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to log weight.')),
      );
      return;
    }

    final weightController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Today\'s Weight'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                hintText: 'e.g. 70.5',
                suffixText: 'kg',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final w = double.tryParse(weightController.text.trim());
              if (w == null || w < 20 || w > 300) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter a valid weight (20-300 kg)'),
                  ),
                );
                return;
              }

              Navigator.pop(ctx);
              try {
                final progressProv = context.read<ProgressProvider>();
                final success = await progressProv.logWeight(
                  userId: userId,
                  weight: w,
                );

                if (context.mounted) {
                  // Also update AuthProvider in-memory profile safely
                  final authProv = context.read<AuthProvider>();
                  final userProfile = authProv.userProfile;
                  if (userProfile != null) {
                    authProv.updateUserProfile(
                      userProfile.copyWith(currentWeight: w),
                    );
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Weight logged: $w kg'
                            : (progressProv.errorMessage ??
                                  'Failed to save weight'),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving weight: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
