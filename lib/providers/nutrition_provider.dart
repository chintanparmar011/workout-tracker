import 'package:flutter/material.dart';
import '../models/food_model.dart';
import '../models/food_log_model.dart';
import '../models/diet_plan_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/nutrition_service.dart';

class NutritionProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final NutritionService _nutritionService = NutritionService();

  DateTime _selectedDate = DateTime.now();
  List<FoodLogModel> _dailyLogs = [];
  List<FoodModel> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String? _errorMessage;

  DateTime get selectedDate => _selectedDate;
  List<FoodLogModel> get dailyLogs => _dailyLogs;
  List<FoodModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get errorMessage => _errorMessage;

  // Aggregate consumed macros for selected date
  double get totalCalories => _dailyLogs.fold(0.0, (sum, item) => sum + (item.calories * item.quantity));
  double get totalProtein => _dailyLogs.fold(0.0, (sum, item) => sum + (item.protein * item.quantity));
  double get totalCarbs => _dailyLogs.fold(0.0, (sum, item) => sum + (item.carbs * item.quantity));
  double get totalFat => _dailyLogs.fold(0.0, (sum, item) => sum + (item.fat * item.quantity));

  // Goal-based targets (Section 20 of project document)
  int calculateTargetCalories(UserModel? user) {
    if (user == null) return 2400;
    final weight = user.currentWeight ?? 70.0;

    switch (user.fitnessGoal) {
      case 'gain_weight':
        return ((weight * 35) + 400).round();
      case 'build_muscle':
        return ((weight * 33) + 250).round();
      case 'lose_weight':
        return ((weight * 28) - 400).clamp(1400, 3500).round();
      case 'maintain_weight':
      case 'improve_fitness':
      default:
        return (weight * 32).round();
    }
  }

  int calculateTargetProtein(UserModel? user) {
    final weight = user?.currentWeight ?? 70.0;
    switch (user?.fitnessGoal) {
      case 'build_muscle':
      case 'gain_weight':
        return (weight * 2.0).round(); // ~2g/kg
      case 'lose_weight':
        return (weight * 2.2).round(); // High protein to preserve lean mass
      default:
        return (weight * 1.6).round();
    }
  }

  int calculateTargetCarbs(UserModel? user, int targetCalories, int targetProtein) {
    // 4 kcal per gram of protein and carb, 9 kcal per gram of fat
    final proteinCalories = targetProtein * 4;
    final remainingCalories = targetCalories - proteinCalories;
    // ~60% of remainder to carbs
    return ((remainingCalories * 0.60) / 4).round().clamp(100, 500);
  }

  int calculateTargetFat(UserModel? user, int targetCalories, int targetProtein) {
    final proteinCalories = targetProtein * 4;
    final remainingCalories = targetCalories - proteinCalories;
    // ~40% of remainder to fat
    return ((remainingCalories * 0.40) / 9).round().clamp(40, 150);
  }

  double remainingCalories(UserModel? user) {
    final target = calculateTargetCalories(user);
    final remaining = target - totalCalories;
    return remaining > 0 ? remaining : 0.0;
  }

  Future<void> changeDate(String userId, DateTime newDate) async {
    _selectedDate = newDate;
    notifyListeners();
    await loadDailyLogs(userId, newDate);
  }

  Future<void> loadDailyLogs(String userId, [DateTime? date]) async {
    final targetDate = date ?? _selectedDate;
    _isLoading = true;
    notifyListeners();

    try {
      _dailyLogs = await _firestoreService.getFoodLogsForDate(userId, targetDate);
    } catch (_) {
      _dailyLogs = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addFoodLog({
    required String userId,
    required FoodModel food,
    required double quantity,
    required String mealType,
  }) async {
    final log = FoodLogModel(
      id: '',
      foodId: food.id,
      foodName: food.displayName,
      quantity: quantity,
      calories: food.calories,
      protein: food.protein,
      carbs: food.carbs,
      fat: food.fat,
      mealType: mealType,
      date: _selectedDate,
    );

    // Optimistic local add
    _dailyLogs.add(log);
    notifyListeners();

    final success = await _firestoreService.addFoodLog(userId, log);
    if (!success) {
      _dailyLogs.remove(log);
      notifyListeners();
      return false;
    }

    // Refresh logs to fetch server-assigned ID
    loadDailyLogs(userId, _selectedDate);
    return true;
  }

  Future<bool> deleteFoodLog(String userId, String logId) async {
    final index = _dailyLogs.indexWhere((l) => l.id == logId);
    if (index == -1) return false;

    final removed = _dailyLogs.removeAt(index);
    notifyListeners();

    final success = await _firestoreService.deleteFoodLog(userId, logId);
    if (!success) {
      _dailyLogs.insert(index, removed);
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<void> searchFoods(String query) async {
    _isSearching = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _searchResults = await _nutritionService.searchFoods(query);
    } catch (e) {
      _searchResults = _nutritionService.getCommonFoods();
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  DietPlanModel getDietPlan(String goal) {
    return _nutritionService.getDietPlanForGoal(goal);
  }
}
