import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workout_provider.dart';
import '../../models/workout_model.dart';
import '../../models/exercise_model.dart';
import 'active_workout_screen.dart';

class StrengthScreen extends StatefulWidget {
  const StrengthScreen({super.key});

  @override
  State<StrengthScreen> createState() => _StrengthScreenState();
}

class _StrengthScreenState extends State<StrengthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedMuscleGroup;
  String _selectedLibraryMuscle = 'Chest';

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
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().userProfile;
      final workoutProvider = context.read<WorkoutProvider>();

      if (user != null) {
        workoutProvider.loadPlans(user.fitnessGoal, user.fitnessLevel);
      } else {
        workoutProvider.loadPlans('build_muscle', 'beginner');
      }

      workoutProvider.loadExercisesForMuscle(_selectedLibraryMuscle);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workoutProvider = context.watch<WorkoutProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Strength Training'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.deepOrange,
          labelColor: Colors.deepOrange,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Workout Plans'),
            Tab(text: 'Exercise Library'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPlansTab(workoutProvider),
          _buildExercisesTab(workoutProvider),
        ],
      ),
    );
  }

  Widget _buildPlansTab(WorkoutProvider workoutProvider) {
    final filteredPlans = _selectedMuscleGroup == null
        ? workoutProvider.availablePlans
        : workoutProvider.availablePlans
            .where((p) => p.muscleGroup.toLowerCase() == _selectedMuscleGroup!.toLowerCase())
            .toList();

    return Column(
      children: [
        // Muscle Group Selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('All'),
                  selected: _selectedMuscleGroup == null,
                  onSelected: (_) => setState(() => _selectedMuscleGroup = null),
                ),
              ),
              ..._muscleGroups.map(
                (group) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(group),
                    selected: _selectedMuscleGroup == group,
                    onSelected: (selected) {
                      setState(() => _selectedMuscleGroup = selected ? group : null);
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
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fitness_center, size: 54, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          const Text('No workout plans found for this group.'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              final user = context.read<AuthProvider>().userProfile;
                              workoutProvider.loadPlans(
                                user?.fitnessGoal ?? 'build_muscle',
                                user?.fitnessLevel ?? 'beginner',
                              );
                            },
                            child: const Text('Reload Plans'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredPlans.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemBuilder: (context, index) {
                        final plan = filteredPlans[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _startWorkoutDialog(plan),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.deepOrange.withValues(alpha: 0.1),
                                    child: const Icon(Icons.fitness_center, color: Colors.deepOrange),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          plan.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${plan.exerciseIds.length} exercises • ~${plan.estimatedDuration} mins',
                                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.play_circle_fill, color: Colors.deepOrange, size: 32),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildExercisesTab(WorkoutProvider workoutProvider) {
    return Column(
      children: [
        // Muscle Group Selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: _muscleGroups.map(
              (group) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(group),
                  selected: _selectedLibraryMuscle == group,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedLibraryMuscle = group);
                      workoutProvider.loadExercisesForMuscle(group);
                    }
                  },
                ),
              ),
            ).toList(),
          ),
        ),

        Expanded(
          child: workoutProvider.isMuscleLoading
              ? const Center(child: CircularProgressIndicator())
              : workoutProvider.muscleGroupExercises.isEmpty
                  ? Center(
                      child: Text('No exercises found for $_selectedLibraryMuscle.'),
                    )
                  : ListView.separated(
                      itemCount: workoutProvider.muscleGroupExercises.length,
                      padding: const EdgeInsets.all(16),
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final ex = workoutProvider.muscleGroupExercises[index];
                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            title: Text(ex.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${ex.equipment} • ${ex.targetSets} sets x ${ex.targetReps} reps'),
                            trailing: const Icon(Icons.info_outline, color: Colors.grey),
                            onTap: () => _showExerciseDetails(ex),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _showExerciseDetails(ExerciseModel ex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              ex.displayName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Muscle Group: ${ex.muscleGroup} • Equipment: ${ex.equipment}',
              style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.w500),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailBadge('Sets', '${ex.targetSets}'),
                _buildDetailBadge('Reps', '${ex.targetReps}'),
                _buildDetailBadge('Rest', '${ex.restSeconds}s'),
                _buildDetailBadge('Difficulty', ex.difficulty.toUpperCase()),
              ],
            ),
            const Divider(height: 24),
            const Text('Instructions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              ex.instructions.isNotEmpty ? ex.instructions : 'Perform controlled repetitions maintaining good form.',
              style: const TextStyle(height: 1.5, fontSize: 14),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailBadge(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  void _startWorkoutDialog(WorkoutPlanModel plan) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(plan.name),
        content: Text('${plan.description}\n\nEstimated duration: ~${plan.estimatedDuration} minutes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
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
