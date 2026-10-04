import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workout_provider.dart';
import '../../models/workout_model.dart';
import '../../models/exercise_model.dart';
import 'active_workout_screen.dart';
import 'create_custom_plan_screen.dart';

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
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().userProfile;
      final workoutProvider = context.read<WorkoutProvider>();

      if (user != null) {
        workoutProvider.loadPlans(user.fitnessGoal, user.fitnessLevel);
        workoutProvider.loadCustomPlans(user.uid);
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
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              heroTag: 'strength_create_plan_fab',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateCustomPlanScreen(),
                  ),
                );
              },
              backgroundColor: Colors.deepOrange,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Create Plan',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
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
            .where(
              (p) =>
                  p.muscleGroup.toLowerCase() ==
                  _selectedMuscleGroup!.toLowerCase(),
            )
            .toList();

    final customPlans = workoutProvider.customPlans;

    return RefreshIndicator(
      onRefresh: () async {
        final user = context.read<AuthProvider>().userProfile;
        if (user != null) {
          await workoutProvider.loadPlans(user.fitnessGoal, user.fitnessLevel);
          await workoutProvider.loadCustomPlans(user.uid);
        }
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          // Banner: Create Custom Workout
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateCustomPlanScreen(),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepOrange, Colors.orange.shade700],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepOrange.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Create Custom Workout Plan',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Pick exercises & tailor your routine',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white70,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),

          // User Custom Plans Section (if any exist)
          if (customPlans.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Custom Plans (${customPlans.length})',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateCustomPlanScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New'),
                  ),
                ],
              ),
            ),
            ...customPlans.map((plan) {
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.deepOrange.withValues(alpha: 0.4),
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _startWorkoutDialog(plan),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.deepOrange.withValues(
                            alpha: 0.15,
                          ),
                          child: const Icon(
                            Icons.stars,
                            color: Colors.deepOrange,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      plan.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.deepOrange.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'CUSTOM',
                                      style: TextStyle(
                                        color: Colors.deepOrange,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${plan.exerciseIds.length} exercises • ~${plan.estimatedDuration} mins • ${plan.muscleGroup}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.grey,
                          ),
                          tooltip: 'Delete custom plan',
                          onPressed: () => _confirmDeleteCustomPlan(plan),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.play_circle_fill,
                            color: Colors.deepOrange,
                            size: 32,
                          ),
                          tooltip: 'Start workout',
                          onPressed: () => _startWorkoutDialog(plan),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const Divider(height: 32, indent: 16, endIndent: 16),
          ],

          // Curated Plans Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: const Text(
              'Curated Workout Plans',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),

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

          if (workoutProvider.isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filteredPlans.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 54,
                      color: Colors.grey[400],
                    ),
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
              ),
            )
          else
            ...filteredPlans.map((plan) {
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 7,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _startWorkoutDialog(plan),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.deepOrange.withValues(
                            alpha: 0.1,
                          ),
                          child: const Icon(
                            Icons.fitness_center,
                            color: Colors.deepOrange,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plan.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${plan.exerciseIds.length} exercises • ~${plan.estimatedDuration} mins',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.play_circle_fill,
                          color: Colors.deepOrange,
                          size: 32,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
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
                      separatorBuilder: (_, index) => const SizedBox(height: 8),
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

  void _confirmDeleteCustomPlan(WorkoutPlanModel plan) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Custom Plan'),
        content: Text('Are you sure you want to delete "${plan.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final user = context.read<AuthProvider>().userProfile;
              final success = await context.read<WorkoutProvider>().deleteCustomPlan(
                    user?.uid ?? 'guest',
                    plan.id,
                  );
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted "${plan.name}"'),
                    backgroundColor: Colors.deepOrange,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
