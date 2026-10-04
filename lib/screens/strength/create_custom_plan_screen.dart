import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/workout_model.dart';
import '../../models/exercise_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workout_provider.dart';
import '../../services/exercise_service.dart';

class CreateCustomPlanScreen extends StatefulWidget {
  const CreateCustomPlanScreen({super.key});

  @override
  State<CreateCustomPlanScreen> createState() => _CreateCustomPlanScreenState();
}

class _CreateCustomPlanScreenState extends State<CreateCustomPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  final ExerciseService _exerciseService = ExerciseService();

  String _selectedMuscleCategory = 'Full Body';
  String _selectedFitnessLevel = 'intermediate';
  int _estimatedDuration = 45;

  List<ExerciseModel> _allAvailableExercises = [];
  List<ExerciseModel> _filteredExercises = [];
  final Set<String> _selectedExerciseIds = {};
  String _searchQuery = '';
  String _filterMuscleGroup = 'All';
  bool _isSaving = false;

  final List<String> _categories = [
    'Full Body',
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Core',
    'Push',
    'Pull',
    'Mixed',
  ];

  final List<String> _filterGroups = [
    'All',
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
    _loadExercises();
  }

  void _loadExercises() {
    final exercises = _exerciseService.getAllCuratedExercises();
    setState(() {
      _allAvailableExercises = exercises;
      _applyExerciseFilter();
    });
  }

  void _applyExerciseFilter() {
    List<ExerciseModel> list = List.from(_allAvailableExercises);

    if (_filterMuscleGroup != 'All') {
      list = list.where((e) {
        if (_filterMuscleGroup == 'Abs/Core') {
          return e.muscleGroup.toLowerCase().contains('core') ||
              e.muscleGroup.toLowerCase().contains('abs');
        }
        return e.muscleGroup.toLowerCase() == _filterMuscleGroup.toLowerCase();
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      list = list.where((e) {
        return e.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            e.muscleGroup.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            e.equipment.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    _filteredExercises = list;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedExerciseIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 1 exercise for your custom plan'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final workoutProvider = context.read<WorkoutProvider>();
    final userId = authProvider.userProfile?.uid ?? 'guest';

    setState(() => _isSaving = true);

    final plan = WorkoutPlanModel(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      goal: authProvider.userProfile?.fitnessGoal ?? 'custom',
      fitnessLevel: _selectedFitnessLevel,
      muscleGroup: _selectedMuscleCategory,
      description: _descriptionController.text.trim().isEmpty
          ? 'Personalized custom workout created in OmniFit'
          : _descriptionController.text.trim(),
      exerciseIds: _selectedExerciseIds.toList(),
      estimatedDuration: _estimatedDuration,
    );

    final success = await workoutProvider.saveCustomPlan(userId, plan);

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Custom plan "${plan.name}" created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save workout plan. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Custom Workout Plan'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _savePlan,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check, color: Colors.white),
            label: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Plan Basic Details Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Plan Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Plan Name *',
                        hintText: 'e.g. Upper Body Blast, Arm Finisher',
                        prefixIcon: Icon(Icons.fitness_center),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter a name for your workout plan';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        hintText: 'Notes, intensity focus, or target goals',
                        prefixIcon: Icon(Icons.notes),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedMuscleCategory,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                            ),
                            items: _categories.map((c) {
                              return DropdownMenuItem(value: c, child: Text(c));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedMuscleCategory = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedFitnessLevel,
                            decoration: const InputDecoration(
                              labelText: 'Difficulty',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'beginner',
                                child: Text('Beginner'),
                              ),
                              DropdownMenuItem(
                                value: 'intermediate',
                                child: Text('Intermediate'),
                              ),
                              DropdownMenuItem(
                                value: 'advanced',
                                child: Text('Advanced'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedFitnessLevel = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Estimated Duration:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '$_estimatedDuration mins',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _estimatedDuration.toDouble(),
                      min: 15,
                      max: 120,
                      divisions: 21,
                      activeColor: Colors.deepOrange,
                      label: '$_estimatedDuration mins',
                      onChanged: (val) {
                        setState(() => _estimatedDuration = val.round());
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Exercise Selection Header with Counter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Exercises',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _selectedExerciseIds.isNotEmpty
                        ? Colors.deepOrange
                        : Colors.grey[400],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_selectedExerciseIds.length} Selected',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search exercises by name or equipment...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _applyExerciseFilter();
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                  _applyExerciseFilter();
                });
              },
            ),
            const SizedBox(height: 10),

            // Muscle filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterGroups.map((group) {
                  final isSelected = _filterMuscleGroup == group;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(group),
                      selected: isSelected,
                      selectedColor: Colors.deepOrange.withValues(alpha: 0.2),
                      checkmarkColor: Colors.deepOrange,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.deepOrange : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _filterMuscleGroup = group;
                          _applyExerciseFilter();
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Exercise Selection List
            if (_filteredExercises.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No exercises found matching criteria.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredExercises.length,
                itemBuilder: (context, index) {
                  final exercise = _filteredExercises[index];
                  final isChecked = _selectedExerciseIds.contains(exercise.id);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isChecked
                            ? Colors.deepOrange
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: CheckboxListTile(
                      value: isChecked,
                      activeColor: Colors.deepOrange,
                      title: Text(
                        exercise.displayName,
                        style: TextStyle(
                          fontWeight:
                              isChecked ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${exercise.muscleGroup} • ${exercise.equipment}\n${exercise.targetSets} sets x ${exercise.targetReps} reps',
                      ),
                      isThreeLine: true,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedExerciseIds.add(exercise.id);
                          } else {
                            _selectedExerciseIds.remove(exercise.id);
                          }
                        });
                      },
                    ),
                  );
                },
              ),

            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _savePlan,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                _isSaving
                    ? 'Saving Custom Plan...'
                    : 'Save Custom Workout Plan (${_selectedExerciseIds.length} exercises)',
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
