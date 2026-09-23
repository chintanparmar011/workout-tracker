import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workout_provider.dart';
import '../../models/workout_model.dart';
import 'active_workout_screen.dart';

class StrengthScreen extends StatefulWidget {
  const StrengthScreen({super.key});

  @override
  State<StrengthScreen> createState() => _StrengthScreenState();
}

class _StrengthScreenState extends State<StrengthScreen> {
  String? _selectedMuscleGroup;

  final List<String> _muscleGroups = [
    'Chest',
    'Back',
    'Shoulders',
    'Biceps',
    'Triceps',
    'Legs',
    'Abs/Core',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-load plans for the user's goal/level
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().userProfile;
      if (user != null) {
        context.read<WorkoutProvider>().loadPlans(
          user.fitnessGoal,
          user.fitnessLevel,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final workoutProvider = context.watch<WorkoutProvider>();
    final user = context.watch<AuthProvider>().userProfile;

    // Filter plans based on selected muscle group
    final filteredPlans = _selectedMuscleGroup == null
        ? workoutProvider.availablePlans
        : workoutProvider.availablePlans
              .where(
                (p) =>
                    p.muscleGroup.toLowerCase() ==
                    _selectedMuscleGroup!.toLowerCase(),
              )
              .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Strength Training')),
      body: Column(
        children: [
          // Muscle Group Selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('All'),
                    selected: _selectedMuscleGroup == null,
                    onSelected: (_) =>
                        setState(() => _selectedMuscleGroup = null),
                  ),
                ),
                ..._muscleGroups.map(
                  (group) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(group),
                      selected: _selectedMuscleGroup == group,
                      onSelected: (selected) {
                        setState(
                          () => _selectedMuscleGroup = selected ? group : null,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: workoutProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredPlans.isEmpty
                ? const Center(
                    child: Text('No workout plans found for this group.'),
                  )
                : ListView.builder(
                    itemCount: filteredPlans.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final plan = filteredPlans[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          title: Text(
                            plan.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${plan.exerciseIds.length} exercises • ${plan.estimatedDuration} mins',
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () => _startWorkout(plan),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _startWorkout(WorkoutPlanModel plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(plan.name),
        content: Text(plan.description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<WorkoutProvider>().startWorkout(plan);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
              );
            },
            child: const Text('Start Workout'),
          ),
        ],
      ),
    );
  }
}
