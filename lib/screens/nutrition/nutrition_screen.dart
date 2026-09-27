import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/nutrition_provider.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<NutritionProvider>().loadDailyLogs(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition & Diet'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.deepOrange,
          labelColor: Colors.deepOrange,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Daily Tracker'),
            Tab(text: 'Diet Plans'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [const _DailyTrackerTab(), const _DietPlansTab()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddFoodDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Log Food'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _openAddFoodDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _AddFoodSheet(),
    );
  }
}

class _DailyTrackerTab extends StatelessWidget {
  const _DailyTrackerTab();

  @override
  Widget build(BuildContext context) {
    final nutrition = context.watch<NutritionProvider>();
    final user = context.watch<AuthProvider>().userProfile;
    final currentUserId = context.watch<AuthProvider>().user?.uid ?? '';

    final targetCalories = nutrition.calculateTargetCalories(user);
    final targetProtein = nutrition.calculateTargetProtein(user);
    final targetCarbs = nutrition.calculateTargetCarbs(
      user,
      targetCalories,
      targetProtein,
    );
    final targetFat = nutrition.calculateTargetFat(
      user,
      targetCalories,
      targetProtein,
    );

    final consumedCalories = nutrition.totalCalories;
    final remaining = (targetCalories - consumedCalories)
        .clamp(0, 9999)
        .toDouble();

    final isToday = DateUtils.isSameDay(nutrition.selectedDate, DateTime.now());

    return RefreshIndicator(
      onRefresh: () async {
        if (currentUserId.isNotEmpty) {
          await nutrition.loadDailyLogs(currentUserId);
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Date Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  final prev = nutrition.selectedDate.subtract(
                    const Duration(days: 1),
                  );
                  nutrition.changeDate(currentUserId, prev);
                },
              ),
              Text(
                isToday
                    ? 'Today, ${DateFormat('MMM d').format(nutrition.selectedDate)}'
                    : DateFormat('EEE, MMM d').format(nutrition.selectedDate),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  final next = nutrition.selectedDate.add(
                    const Duration(days: 1),
                  );
                  nutrition.changeDate(currentUserId, next);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Daily Calories Card (Section 20)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Daily Calories',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCalorieCol(
                        'Target',
                        '$targetCalories kcal',
                        Colors.grey[700]!,
                      ),
                      _buildCalorieCol(
                        'Consumed',
                        '${consumedCalories.toStringAsFixed(0)} kcal',
                        Colors.deepOrange,
                      ),
                      _buildCalorieCol(
                        'Remaining',
                        '${remaining.toStringAsFixed(0)} kcal',
                        Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: targetCalories > 0
                          ? (consumedCalories / targetCalories).clamp(0.0, 1.0)
                          : 0.0,
                      backgroundColor: Colors.grey[200],
                      color: Colors.deepOrange,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),

                  // Macronutrients Progress (Section 20)
                  _buildMacroBar(
                    'Protein',
                    nutrition.totalProtein,
                    targetProtein.toDouble(),
                    'g',
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildMacroBar(
                    'Carbohydrates',
                    nutrition.totalCarbs,
                    targetCarbs.toDouble(),
                    'g',
                    Colors.amber[800]!,
                  ),
                  const SizedBox(height: 12),
                  _buildMacroBar(
                    'Fat',
                    nutrition.totalFat,
                    targetFat.toDouble(),
                    'g',
                    Colors.red[400]!,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Food Logs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Logged Meals',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${nutrition.dailyLogs.length} items',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (nutrition.isLoading && nutrition.dailyLogs.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (nutrition.dailyLogs.isEmpty)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 36,
                  horizontal: 20,
                ),
                child: Column(
                  children: [
                    Icon(Icons.restaurant, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    const Text(
                      'No food logged for this day',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap "Log Food" below to search and add meals.',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            ...nutrition.dailyLogs.map(
              (log) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepOrange.withValues(alpha: 0.1),
                    child: Icon(
                      _getMealIcon(log.mealType),
                      color: Colors.deepOrange,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    log.foodName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${log.mealType.toUpperCase()} • ${(log.calories * log.quantity).toStringAsFixed(0)} kcal (P: ${(log.protein * log.quantity).toStringAsFixed(1)}g, C: ${(log.carbs * log.quantity).toStringAsFixed(1)}g, F: ${(log.fat * log.quantity).toStringAsFixed(1)}g)',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.grey,
                    ),
                    onPressed: () =>
                        nutrition.deleteFoodLog(currentUserId, log.id),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 80), // Padding for FAB
        ],
      ),
    );
  }

  IconData _getMealIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      default:
        return Icons.bakery_dining;
    }
  }

  Widget _buildCalorieCol(String title, String val, Color color) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildMacroBar(
    String name,
    double current,
    double target,
    String unit,
    Color color,
  ) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
            Text(
              '${current.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} $unit',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            color: color,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _DietPlansTab extends StatelessWidget {
  const _DietPlansTab();

  @override
  Widget build(BuildContext context) {
    final nutrition = context.watch<NutritionProvider>();
    final user = context.watch<AuthProvider>().userProfile;
    final goal = user?.fitnessGoal ?? 'build_muscle';
    final plan = nutrition.getDietPlan(goal);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          color: Colors.deepOrange.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: Colors.deepOrange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        plan.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  plan.description,
                  style: TextStyle(color: Colors.grey[800], fontSize: 14),
                ),
                const SizedBox(height: 10),
                Text(
                  'Daily Estimated Energy: ~${plan.totalCalories} kcal',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Suggested Daily Meal Structure',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        ...plan.meals.map(
          (m) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        m.mealType,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '~${m.estimatedCalories} kcal • ${m.estimatedProtein}g protein',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  ...m.foods.map(
                    (f) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              f,
                              style: const TextStyle(fontSize: 14),
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
        ),
      ],
    );
  }
}

class _AddFoodSheet extends StatefulWidget {
  const _AddFoodSheet();

  @override
  State<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<_AddFoodSheet> {
  final _searchController = TextEditingController();
  String _selectedMeal = 'Lunch';
  double _servings = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NutritionProvider>().searchFoods('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nutrition = context.watch<NutritionProvider>();
    final currentUserId = context.watch<AuthProvider>().user?.uid ?? '';

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Search & Log Food',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Search input (USDA + local fallback)
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search food (e.g. Chicken, Banana, Oats)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    nutrition.searchFoods('');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onSubmitted: (query) => nutrition.searchFoods(query),
            ),
            const SizedBox(height: 12),

            // Meal Type and Servings selector
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedMeal,
                    decoration: const InputDecoration(
                      labelText: 'Meal Type',
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Breakfast',
                        child: Text('Breakfast'),
                      ),
                      DropdownMenuItem(value: 'Lunch', child: Text('Lunch')),
                      DropdownMenuItem(value: 'Dinner', child: Text('Dinner')),
                      DropdownMenuItem(value: 'Snack', child: Text('Snack')),
                    ],
                    onChanged: (v) =>
                        setState(() => _selectedMeal = v ?? 'Lunch'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<double>(
                    initialValue: _servings,
                    decoration: const InputDecoration(
                      labelText: 'Servings',
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 0.5, child: Text('0.5 serving')),
                      DropdownMenuItem(value: 1.0, child: Text('1.0 serving')),
                      DropdownMenuItem(value: 1.5, child: Text('1.5 servings')),
                      DropdownMenuItem(value: 2.0, child: Text('2.0 servings')),
                      DropdownMenuItem(value: 3.0, child: Text('3.0 servings')),
                    ],
                    onChanged: (v) => setState(() => _servings = v ?? 1.0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Expanded(
              child: nutrition.isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : nutrition.searchResults.isEmpty
                  ? const Center(child: Text('No matching foods found.'))
                  : ListView.separated(
                      controller: scrollController,
                      itemCount: nutrition.searchResults.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final food = nutrition.searchResults[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            title: Text(
                              food.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${food.servingSize} • ${(food.calories * _servings).toStringAsFixed(0)} kcal • P: ${(food.protein * _servings).toStringAsFixed(1)}g, C: ${(food.carbs * _servings).toStringAsFixed(1)}g, F: ${(food.fat * _servings).toStringAsFixed(1)}g',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              onPressed: () async {
                                if (currentUserId.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please sign in to log food.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                try {
                                  final success = await nutrition.addFoodLog(
                                    userId: currentUserId,
                                    food: food,
                                    quantity: _servings,
                                    mealType: _selectedMeal,
                                  );
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          success
                                              ? 'Logged ${food.displayName} to $_selectedMeal'
                                              : (nutrition.errorMessage ??
                                                    'Failed to log food'),
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error logging food: $e'),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text('Add'),
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
}
