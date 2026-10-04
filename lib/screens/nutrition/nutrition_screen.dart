import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../models/user_model.dart';
import '../../models/food_log_model.dart';

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
        heroTag: 'nutrition_log_food_fab',
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

    final today = DateUtils.dateOnly(DateTime.now());
    final accountCreatedAt = user != null
        ? DateUtils.dateOnly(user.createdAt)
        : today.subtract(const Duration(days: 365));
    final currentDate = DateUtils.dateOnly(nutrition.selectedDate);

    final canGoForward = currentDate.isBefore(today);
    final canGoBack = currentDate.isAfter(accountCreatedAt);
    final isToday = DateUtils.isSameDay(currentDate, today);

    return RefreshIndicator(
      onRefresh: () async {
        if (currentUserId.isNotEmpty) {
          await nutrition.loadDailyLogs(currentUserId);
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Date Selector & History Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: canGoBack ? 'Previous Day' : 'Reached account creation date',
                  onPressed: canGoBack
                      ? () {
                          final prev = currentDate.subtract(const Duration(days: 1));
                          nutrition.changeDate(
                            currentUserId,
                            prev,
                            minDate: accountCreatedAt,
                            maxDate: today,
                          );
                        }
                      : null,
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: currentDate.isAfter(today)
                          ? today
                          : (currentDate.isBefore(accountCreatedAt)
                              ? accountCreatedAt
                              : currentDate),
                      firstDate: accountCreatedAt,
                      lastDate: today,
                      helpText: 'SELECT INTAKE DATE',
                    );
                    if (picked != null) {
                      nutrition.changeDate(
                        currentUserId,
                        picked,
                        minDate: accountCreatedAt,
                        maxDate: today,
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: isToday ? Colors.deepOrange : Colors.grey[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isToday
                              ? 'Today, ${DateFormat('MMM d').format(currentDate)}'
                              : DateFormat('EEE, MMM d').format(currentDate),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isToday ? Colors.deepOrange : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.history),
                      tooltip: 'Calorie Intake History',
                      onPressed: () => _openHistorySheet(
                        context,
                        currentUserId,
                        user,
                        targetCalories,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      tooltip: canGoForward
                          ? 'Next Day'
                          : 'Cannot navigate beyond today',
                      onPressed: canGoForward
                          ? () {
                              final next = currentDate.add(const Duration(days: 1));
                              nutrition.changeDate(
                                currentUserId,
                                next,
                                minDate: accountCreatedAt,
                                maxDate: today,
                              );
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
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

void _openHistorySheet(
  BuildContext context,
  String userId,
  UserModel? user,
  int targetCalories,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _CalorieHistorySheet(
      userId: userId,
      user: user,
      targetCalories: targetCalories,
    ),
  );
}

class _CalorieHistorySheet extends StatefulWidget {
  final String userId;
  final UserModel? user;
  final int targetCalories;

  const _CalorieHistorySheet({
    required this.userId,
    required this.user,
    required this.targetCalories,
  });

  @override
  State<_CalorieHistorySheet> createState() => _CalorieHistorySheetState();
}

class _CalorieHistorySheetState extends State<_CalorieHistorySheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.userId.isNotEmpty) {
        context.read<NutritionProvider>().loadFoodHistory(widget.userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final nutrition = context.watch<NutritionProvider>();
    final today = DateUtils.dateOnly(DateTime.now());
    final accountCreatedAt = widget.user != null
        ? DateUtils.dateOnly(widget.user!.createdAt)
        : today.subtract(const Duration(days: 30));

    // Group history logs by date
    final Map<DateTime, List<FoodLogModel>> logsByDate = {};
    for (final log in nutrition.historyLogs) {
      final dateKey = DateUtils.dateOnly(log.date);
      // Strictly ignore future dates and dates prior to account creation
      if (!dateKey.isAfter(today) && !dateKey.isBefore(accountCreatedAt)) {
        logsByDate.putIfAbsent(dateKey, () => []).add(log);
      }
    }

    // Build list of all dates from today backwards to accountCreatedAt (up to 45 days)
    final List<DateTime> dateRange = [];
    var cur = today;
    while (!cur.isBefore(accountCreatedAt) && dateRange.length < 45) {
      dateRange.add(cur);
      cur = cur.subtract(const Duration(days: 1));
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Calorie Intake History',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${DateFormat('MMM d').format(accountCreatedAt)} - ${DateFormat('MMM d').format(today)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Only showing dates from account creation to today (${widget.targetCalories} kcal daily target)',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const Divider(height: 24),
              Expanded(
                child: nutrition.isHistoryLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: dateRange.length,
                        itemBuilder: (context, index) {
                          final date = dateRange[index];
                          final logs = logsByDate[date] ?? [];
                          final dayCalories = logs.fold<double>(
                            0.0,
                            (sum, l) => sum + (l.calories * l.quantity),
                          );
                          final dayProtein = logs.fold<double>(
                            0.0,
                            (sum, l) => sum + (l.protein * l.quantity),
                          );
                          final isCurrentDay = DateUtils.isSameDay(
                            date,
                            nutrition.selectedDate,
                          );
                          final isToday = DateUtils.isSameDay(date, today);

                          final double progress = widget.targetCalories > 0
                              ? (dayCalories / widget.targetCalories)
                                  .clamp(0.0, 1.0)
                              : 0.0;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isCurrentDay
                                    ? Colors.deepOrange
                                    : Colors.grey.shade200,
                                width: isCurrentDay ? 1.5 : 1,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                nutrition.changeDate(
                                  widget.userId,
                                  date,
                                  minDate: accountCreatedAt,
                                  maxDate: today,
                                );
                                Navigator.pop(ctx);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              isToday
                                                  ? 'Today (${DateFormat('MMM d').format(date)})'
                                                  : DateFormat('EEEE, MMM d')
                                                      .format(date),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: isToday
                                                    ? Colors.deepOrange
                                                    : Colors.black87,
                                              ),
                                            ),
                                            if (isCurrentDay) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.deepOrange
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  'SELECTED',
                                                  style: TextStyle(
                                                    color: Colors.deepOrange,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        Text(
                                          '${dayCalories.toStringAsFixed(0)} / ${widget.targetCalories} kcal',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: dayCalories > 0
                                                ? Colors.black87
                                                : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        backgroundColor: Colors.grey[200],
                                        color: progress >= 1.0
                                            ? Colors.green
                                            : Colors.deepOrange,
                                        minHeight: 6,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          logs.isEmpty
                                              ? 'No meals logged'
                                              : '${logs.length} item${logs.length > 1 ? 's' : ''} logged • ${dayProtein.toStringAsFixed(0)}g protein',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const Text(
                                          'View details →',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.deepOrange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
