import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_model.dart';
import '../models/diet_plan_model.dart';
import '../utils/api_constants.dart';

class NutritionService {
  static final NutritionService _instance = NutritionService._internal();
  factory NutritionService() => _instance;
  NutritionService._internal();

  /// Search foods using USDA FoodData Central API, with rich fallback to curated common foods.
  Future<List<FoodModel>> searchFoods(String query) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return getCommonFoods();

    // 1. If USDA API key is set (or default DEMO_KEY), try remote USDA search
    if (ApiConstants.usdaApiKey.isNotEmpty) {
      try {
        final url = Uri.parse(
          '${ApiConstants.usdaBaseUrl}/foods/search?query=${Uri.encodeComponent(clean)}&pageSize=20&api_key=${ApiConstants.usdaApiKey}',
        );

        final response = await http.get(url).timeout(const Duration(seconds: 6));
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          final List<dynamic> foodsJson = data['foods'] ?? [];

          final results = foodsJson
              .map((f) => FoodModel.fromUsdaJson(f as Map<String, dynamic>))
              .where((f) => f.calories > 0 || f.protein > 0 || f.carbs > 0)
              .toList();

          if (results.isNotEmpty) {
            return results;
          }
        }
      } catch (_) {
        // Fallback below
      }
    }

    // 2. Fallback to local common foods matching query
    final all = getCommonFoods();
    final matched = all.where((f) => f.name.toLowerCase().contains(clean)).toList();
    return matched.isNotEmpty ? matched : all;
  }

  /// Curated list of staple fitness and health foods with accurate nutritional values
  List<FoodModel> getCommonFoods() {
    return [
      FoodModel(
        id: 'food_chicken_breast',
        name: 'Chicken Breast (Cooked, Skinless)',
        servingSize: '100g',
        calories: 165.0,
        protein: 31.0,
        carbs: 0.0,
        fat: 3.6,
      ),
      FoodModel(
        id: 'food_brown_rice',
        name: 'Brown Rice (Cooked)',
        servingSize: '100g',
        calories: 123.0,
        protein: 2.7,
        carbs: 25.6,
        fat: 1.0,
      ),
      FoodModel(
        id: 'food_egg_whole',
        name: 'Whole Egg (Large)',
        servingSize: '1 egg (50g)',
        calories: 78.0,
        protein: 6.3,
        carbs: 0.6,
        fat: 5.3,
      ),
      FoodModel(
        id: 'food_egg_whites',
        name: 'Egg Whites',
        servingSize: '100g',
        calories: 52.0,
        protein: 11.0,
        carbs: 0.7,
        fat: 0.2,
      ),
      FoodModel(
        id: 'food_rolled_oats',
        name: 'Rolled Oats (Dry)',
        servingSize: '100g',
        calories: 389.0,
        protein: 16.9,
        carbs: 66.3,
        fat: 6.9,
      ),
      FoodModel(
        id: 'food_banana',
        name: 'Banana (Medium)',
        servingSize: '1 fruit (118g)',
        calories: 105.0,
        protein: 1.3,
        carbs: 27.0,
        fat: 0.3,
      ),
      FoodModel(
        id: 'food_whey_protein',
        name: 'Whey Protein Powder',
        servingSize: '1 scoop (30g)',
        calories: 120.0,
        protein: 24.0,
        carbs: 3.0,
        fat: 1.5,
      ),
      FoodModel(
        id: 'food_peanut_butter',
        name: 'Natural Peanut Butter',
        servingSize: '2 tbsp (32g)',
        calories: 188.0,
        protein: 8.0,
        carbs: 6.0,
        fat: 16.0,
      ),
      FoodModel(
        id: 'food_greek_yogurt',
        name: 'Greek Yogurt (Plain, 0% Fat)',
        servingSize: '100g',
        calories: 59.0,
        protein: 10.0,
        carbs: 3.6,
        fat: 0.4,
      ),
      FoodModel(
        id: 'food_salmon',
        name: 'Atlantic Salmon (Cooked)',
        servingSize: '100g',
        calories: 206.0,
        protein: 22.1,
        carbs: 0.0,
        fat: 12.3,
      ),
      FoodModel(
        id: 'food_sweet_potato',
        name: 'Sweet Potato (Baked)',
        servingSize: '100g',
        calories: 90.0,
        protein: 2.0,
        carbs: 20.7,
        fat: 0.2,
      ),
      FoodModel(
        id: 'food_broccoli',
        name: 'Steamed Broccoli',
        servingSize: '100g',
        calories: 35.0,
        protein: 2.4,
        carbs: 7.2,
        fat: 0.4,
      ),
      FoodModel(
        id: 'food_whole_milk',
        name: 'Whole Milk',
        servingSize: '1 cup (244g)',
        calories: 149.0,
        protein: 7.7,
        carbs: 11.7,
        fat: 8.0,
      ),
      FoodModel(
        id: 'food_almonds',
        name: 'Raw Almonds',
        servingSize: '1 oz (28g)',
        calories: 164.0,
        protein: 6.0,
        carbs: 6.0,
        fat: 14.0,
      ),
    ];
  }

  /// Returns predefined structured diet plans based on the user's fitness goal.
  DietPlanModel getDietPlanForGoal(String goal) {
    switch (goal.toLowerCase()) {
      case 'gain_weight':
        return DietPlanModel(
          id: 'diet_gain_weight',
          name: 'Weight & Mass Gainer Routine',
          goal: 'gain_weight',
          description: 'High-density nutrient distribution designed for healthy weight gain and surplus.',
          meals: [
            DietMeal(
              mealType: 'Breakfast',
              foods: ['Oats (80g) with Whole Milk & Honey', '2 Whole Eggs', '1 Banana'],
              estimatedCalories: 680,
              estimatedProtein: 28,
            ),
            DietMeal(
              mealType: 'Lunch',
              foods: ['Chicken Breast or Paneer (150g)', 'Cooked Rice (200g)', 'Mixed Steamed Vegetables & Olive Oil'],
              estimatedCalories: 750,
              estimatedProtein: 48,
            ),
            DietMeal(
              mealType: 'Snack',
              foods: ['Handful of Almonds & Walnuts', 'Apple with 2 tbsp Peanut Butter', 'Whey Protein Shake'],
              estimatedCalories: 520,
              estimatedProtein: 32,
            ),
            DietMeal(
              mealType: 'Dinner',
              foods: ['Grilled Fish or Tofu (150g)', 'Sweet Potato or 3 Whole Wheat Chapatis', 'Green Salad'],
              estimatedCalories: 650,
              estimatedProtein: 42,
            ),
          ],
        );

      case 'lose_weight':
        return DietPlanModel(
          id: 'diet_lose_weight',
          name: 'Lean Calorie Deficit Plan',
          goal: 'lose_weight',
          description: 'High-satiety, protein-sparing nutrition maximizing fat loss while preserving lean mass.',
          meals: [
            DietMeal(
              mealType: 'Breakfast',
              foods: ['3 Scrambled Egg Whites + 1 Whole Egg', '1 Slice Whole Grain Toast', 'Black Coffee / Green Tea'],
              estimatedCalories: 320,
              estimatedProtein: 24,
            ),
            DietMeal(
              mealType: 'Lunch',
              foods: ['Grilled Chicken Breast (150g)', '1 Cup Steamed Broccoli & Zucchini', '1/2 Cup Brown Rice'],
              estimatedCalories: 450,
              estimatedProtein: 42,
            ),
            DietMeal(
              mealType: 'Snack',
              foods: ['Greek Yogurt (150g)', '1/2 Cup Fresh Berries'],
              estimatedCalories: 180,
              estimatedProtein: 16,
            ),
            DietMeal(
              mealType: 'Dinner',
              foods: ['Baked White Fish or Extra-Firm Tofu (150g)', 'Large Mixed Leafy Salad with Lemon Dressing'],
              estimatedCalories: 380,
              estimatedProtein: 38,
            ),
          ],
        );

      case 'build_muscle':
      default:
        return DietPlanModel(
          id: 'diet_build_muscle',
          name: 'Hypertrophy & Strength Plan',
          goal: 'build_muscle',
          description: 'Optimized macro split with 1.8-2.2g protein/kg to fuel muscle repair and training performance.',
          meals: [
            DietMeal(
              mealType: 'Breakfast',
              foods: ['Oatmeal (60g) with 1 Scoop Whey Protein', '1 Sliced Banana', '1 tbsp Chia Seeds'],
              estimatedCalories: 490,
              estimatedProtein: 36,
            ),
            DietMeal(
              mealType: 'Lunch',
              foods: ['Lean Chicken Breast (160g)', 'Brown Rice or Quinoa (150g)', 'Asparagus & Carrots'],
              estimatedCalories: 580,
              estimatedProtein: 48,
            ),
            DietMeal(
              mealType: 'Snack',
              foods: ['Rice Cakes with Peanut Butter', '1 Hard-boiled Egg'],
              estimatedCalories: 260,
              estimatedProtein: 12,
            ),
            DietMeal(
              mealType: 'Dinner',
              foods: ['Salmon or Lean Beef (150g)', 'Roasted Sweet Potato', 'Spinach Salad with Olive Oil'],
              estimatedCalories: 570,
              estimatedProtein: 44,
            ),
          ],
        );
    }
  }
}
