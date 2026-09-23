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
      return const Scaffold(body: Center(child: Text('No active workout')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(plan.name),
        actions: [
          TextButton(
            onPressed: () => _finishWorkout(context),
            child: const Text('Finish', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: workoutProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: exercises.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                final actualSets = workoutProvider.getSetsForExercise(
                  exercise.id,
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          exercise.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Target: ${exercise.targetSets} sets x ${exercise.targetReps} reps',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const Divider(height: 24),

                        // List of already logged sets
                        ...actualSets.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final set = entry.value;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  child: Text(
                                    '${idx + 1}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${set.reps} reps',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (set.weight > 0) Text(' @ ${set.weight} kg'),
                                const Spacer(),
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 20,
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 12),

                        // Input for new set
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _getController(exercise.id, 'reps'),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Reps',
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _getController(
                                  exercise.id,
                                  'weight',
                                ),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Weight (kg)',
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: () => _addSet(exercise.id),
                              icon: const Icon(
                                Icons.add_circle,
                                color: Colors.deepOrange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  TextEditingController _getController(String id, String type) {
    final key = '$id-$type';
    if (type == 'reps') {
      return _repsControllers.putIfAbsent(key, () => TextEditingController());
    } else {
      return _weightControllers.putIfAbsent(key, () => TextEditingController());
    }
  }

  void _addSet(String exerciseId) {
    final repsText = _getController(exerciseId, 'reps').text;
    final weightText = _getController(exerciseId, 'weight').text;

    final reps = int.tryParse(repsText);
    if (reps == null || reps <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter valid reps')));
      return;
    }

    final weight = double.tryParse(weightText) ?? 0.0;

    context.read<WorkoutProvider>().addSet(exerciseId, reps, weight);

    _getController(exerciseId, 'reps').clear();
    // Keep weight for the next set usually
  }

  Future<void> _finishWorkout(BuildContext context) async {
    final workoutProvider = context.read<WorkoutProvider>();
    final user = context.read<AuthProvider>().userProfile;

    if (user == null) return;

    final success = await workoutProvider.finishWorkout(user.uid);

    if (mounted) {
      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WorkoutSummaryScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save workout.')),
        );
      }
    }
  }
}
