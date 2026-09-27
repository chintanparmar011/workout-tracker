import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workout_provider.dart';
import 'workout_summary_screen.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  final Map<String, TextEditingController> _repsControllers = {};
  final Map<String, TextEditingController> _weightControllers = {};

  @override
  void dispose() {
    for (var c in _repsControllers.values) {
      c.dispose();
    }
    for (var c in _weightControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workoutProvider = context.watch<WorkoutProvider>();
    final plan = workoutProvider.activePlan;
    final exercises = workoutProvider.activeExercises;

    if (plan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active Workout')),
        body: const Center(child: Text('No active workout in progress.')),
      );
    }

    final totalTargetReps = workoutProvider.totalActiveTargetReps;
    final totalActualReps = workoutProvider.totalActiveActualReps;
    final completionPct = workoutProvider.currentCompletionPercent;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _confirmCancelWorkout();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(plan.name),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _confirmCancelWorkout,
          ),
          actions: [
            TextButton(
              onPressed: _confirmFinishWorkout,
              child: const Text(
                'Finish',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        body: workoutProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Progress tracker bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress: $totalActualReps / $totalTargetReps reps',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${completionPct.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: completionPct >= 80 ? Colors.green : Colors.deepOrange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: totalTargetReps > 0 ? (totalActualReps / totalTargetReps).clamp(0.0, 1.0) : 0.0,
                            backgroundColor: Colors.grey[200],
                            color: Colors.deepOrange,
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ListView.builder(
                      itemCount: exercises.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final exercise = exercises[index];
                        final actualSets = workoutProvider.getSetsForExercise(exercise.id);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        exercise.displayName,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Rest: ${exercise.restSeconds}s',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Target: ${exercise.targetSets} sets x ${exercise.targetReps} reps • ${exercise.equipment}',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                ),
                                const Divider(height: 20),

                                // List of completed sets
                                if (actualSets.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      'No sets recorded yet. Log your first set below.',
                                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                                    ),
                                  )
                                else
                                  ...actualSets.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final set = entry.value;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 12,
                                            backgroundColor: Colors.deepOrange.withValues(alpha: 0.1),
                                            child: Text(
                                              '${idx + 1}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.deepOrange,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            '${set.reps} reps',
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                          if (set.weight > 0)
                                            Text(
                                              ' @ ${set.weight} kg',
                                              style: TextStyle(color: Colors.grey[700]),
                                            ),
                                          const Spacer(),
                                          const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    );
                                  }),

                                const SizedBox(height: 12),

                                // Set input row
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _getController(exercise.id, 'reps', defaultText: '${exercise.targetReps}'),
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Reps',
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        controller: _getController(exercise.id, 'weight'),
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(
                                          labelText: 'Weight (kg)',
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton(
                                      onPressed: () => _addSet(exercise.id),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      ),
                                      child: const Text('Add Set'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  TextEditingController _getController(String id, String type, {String defaultText = ''}) {
    final key = '$id-$type';
    if (type == 'reps') {
      return _repsControllers.putIfAbsent(key, () => TextEditingController(text: defaultText));
    } else {
      return _weightControllers.putIfAbsent(key, () => TextEditingController());
    }
  }

  void _addSet(String exerciseId) {
    final repsController = _getController(exerciseId, 'reps');
    final weightController = _getController(exerciseId, 'weight');

    final reps = int.tryParse(repsController.text.trim());
    if (reps == null || reps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid repetitions')),
      );
      return;
    }

    final weight = double.tryParse(weightController.text.trim()) ?? 0.0;
    context.read<WorkoutProvider>().addSet(exerciseId, reps, weight);
  }

  void _confirmCancelWorkout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard Workout?'),
        content: const Text('Are you sure you want to stop this workout? Your recorded sets will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue Workout'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<WorkoutProvider>().cancelActiveWorkout();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  void _confirmFinishWorkout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Workout?'),
        content: const Text('Save your actual performance and view your workout summary?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Training'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _finishWorkout();
            },
            child: const Text('Save & Finish'),
          ),
        ],
      ),
    );
  }

  Future<void> _finishWorkout() async {
    final workoutProvider = context.read<WorkoutProvider>();
    final user = context.read<AuthProvider>().userProfile;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User profile not found.')),
      );
      return;
    }

    final success = await workoutProvider.finishWorkout(user.uid);

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WorkoutSummaryScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save workout. Please try again.')),
      );
    }
  }
}
