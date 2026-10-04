import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/ai_message_model.dart';
import '../utils/api_constants.dart';

class AiFitnessService {
  static final AiFitnessService _instance = AiFitnessService._internal();
  factory AiFitnessService() => _instance;
  AiFitnessService._internal();

  static const String _systemPrompt = '''
You are OmniFit AI Coach, a world-class certified personal trainer and sports nutritionist integrated inside the OmniFit fitness tracking application.

CRITICAL INSTRUCTIONS:
1. RELEVANCE CHECK:
   - Check VERY PRECISELY whether the user query relates to OmniFit application services: workouts, training splits, exercises, muscle building/hypertrophy, fat loss, weight loss, lean bulking, weight gain, calories, diet, meal planning, macronutrients, sports nutrition, recovery, running/cardio, mobility, and fitness supplements.
   - If the query is NOT related to fitness, workouts, sports, or diet (e.g. coding, software, politics, movies, entertainment, general trivia, weather, homework, gaming, relationships, or finance), you MUST politely refuse immediately with:
     "I am **OmniFit AI Coach**, specialized exclusively in fitness, nutrition, and workout training. How can I help you with your exercise routine or diet goals today? 💪"
   - Do NOT attempt to answer non-fitness topics under any circumstance.

2. PRECISION & DIRECTNESS:
   - Answer PRECISELY and DIRECTLY to the user's specific request.
   - Do NOT include generic conversational fluff, filler introductions ("Sure! Let's dive in..."), or repetitive concluding disclaimers.
   - If the user asks for a workout routine (e.g. legs, back, chest), provide the exact exercises, sets, reps, and 1-2 key form cues immediately.
   - If the user asks for diet, calories, or macros, give direct numbers and meal examples tailored to their profile stats.
   - Use structured, punchy formatting (bullet points, bold highlights) designed for fast reading on mobile screens.
   - Keep answers concise and high-impact (under 250 words unless the user explicitly requested a comprehensive multi-day plan).
''';

  /// Sends query to Google Gemini REST API with strict fitness instructions.
  /// Falls back to the built-in OmniFit Fitness Engine if offline or no key is provided.
  Future<AiMessageModel> getFitnessAdvice({
    required String userQuery,
    UserModel? userProfile,
    List<AiMessageModel>? conversationHistory,
    String? customApiKey,
  }) async {
    final apiKey = (customApiKey != null && customApiKey.trim().isNotEmpty)
        ? customApiKey.trim()
        : ApiConstants.geminiApiKey.trim();

    // If API key is available, attempt Gemini REST call
    if (apiKey.isNotEmpty && !apiKey.contains('your_')) {
      try {
        final geminiResponse = await _callGeminiApi(
          apiKey: apiKey,
          userQuery: userQuery,
          userProfile: userProfile,
          conversationHistory: conversationHistory,
        );
        if (geminiResponse != null && geminiResponse.trim().isNotEmpty) {
          return AiMessageModel(
            id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
            content: geminiResponse.trim(),
            isUser: false,
            timestamp: DateTime.now(),
          );
        }
      } catch (_) {
        // Fall back to built-in knowledge engine on error
      }
    }

    // Built-in offline fitness expert intelligence fallback
    final fallbackResponse = _generateBuiltInFitnessResponse(
      userQuery: userQuery,
      userProfile: userProfile,
    );

    return AiMessageModel(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      content: fallbackResponse,
      isUser: false,
      timestamp: DateTime.now(),
    );
  }

  Future<String?> _callGeminiApi({
    required String apiKey,
    required String userQuery,
    UserModel? userProfile,
    List<AiMessageModel>? conversationHistory,
  }) async {
    final model = ApiConstants.geminiModel;
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );

    // Build context with user fitness stats if available
    String contextProfile = '';
    if (userProfile != null) {
      contextProfile = '''
User Stats in OmniFit:
- Name: ${userProfile.name}
- Goal: ${userProfile.fitnessGoal}
- Level: ${userProfile.fitnessLevel}
- Current Weight: ${userProfile.currentWeight ?? 70.0} kg
- Height: ${userProfile.height ?? 175.0} cm
- Target Muscles: ${userProfile.targetMuscles.join(', ')}
''';
    }

    final List<Map<String, dynamic>> contents = [];

    // Include the most recent conversation turns (last 4 for immediate context)
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      final startIndex = conversationHistory.length > 4
          ? conversationHistory.length - 4
          : 0;
      final recent = conversationHistory.sublist(startIndex);
      for (final msg in recent) {
        contents.add({
          'role': msg.isUser ? 'user' : 'model',
          'parts': [{'text': msg.content}],
        });
      }
    }

    // User's current prompt
    contents.add({
      'role': 'user',
      'parts': [
        {
          'text': contextProfile.isNotEmpty
              ? '$contextProfile\nUser question: $userQuery'
              : userQuery,
        }
      ],
    });

    final requestBody = {
      'system_instruction': {
        'parts': [
          {'text': _systemPrompt}
        ]
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.3,
        'maxOutputTokens': 600,
        'thinkingConfig': {
          'thinkingLevel': 'LOW',
        },
      },
    };

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content['parts'] as List<dynamic>?;
        if (parts != null && parts.isNotEmpty) {
          return parts[0]['text'] as String?;
        }
      }
    }
    return null;
  }

  /// Built-in intelligent fitness knowledge engine.
  /// Handles nutrition, muscle growth, weight gain/loss, exercise routines, and guards against non-fitness queries.
  String _generateBuiltInFitnessResponse({
    required String userQuery,
    UserModel? userProfile,
  }) {
    final query = userQuery.toLowerCase().trim();

    // 1. NON-FITNESS GUARDRAIL CHECK
    final nonFitnessKeywords = [
      'code', 'coding', 'python', 'flutter', 'java', 'html', 'css', 'javascript',
      'movie', 'actor', 'president', 'politics', 'election', 'weather',
      'crypto', 'bitcoin', 'stock market', 'finance', 'joke', 'song',
      'who is', 'history of', 'capital of', 'translate', 'car', 'game', 'gaming',
      'travel', 'hotel', 'flight', 'song lyrics', 'story', 'poem', 'homework',
      'math problem', 'algorithm', 'phone price', 'laptop'
    ];

    bool isNonFitness = false;
    for (final kw in nonFitnessKeywords) {
      if (query.contains(kw) &&
          !query.contains('gym') &&
          !query.contains('workout') &&
          !query.contains('diet') &&
          !query.contains('muscle') &&
          !query.contains('exercise') &&
          !query.contains('calorie') &&
          !query.contains('protein')) {
        isNonFitness = true;
        break;
      }
    }

    if (isNonFitness) {
      return 'I am **OmniFit AI Coach**, specialized exclusively in fitness, nutrition, and workout training. How can I help you with your exercise routine or diet goals today? 💪';
    }

    final double weight = userProfile?.currentWeight ?? 70.0;
    final minProtein = (weight * 1.6).round();
    final maxProtein = (weight * 2.2).round();

    // 2. BACK MUSCLE GROWTH & TRAINING
    if (query.contains('back') ||
        query.contains('lat') ||
        query.contains('rhomboid') ||
        query.contains('pullup') ||
        query.contains('row')) {
      return '''
### 🦅 OmniFit Blueprint for Maximum Back Growth & Width

To build a wide "V-Taper" and thick, dense back, you need both vertical and horizontal pulling:

1. **Top Exercises for Back Hypertrophy**
   - **Bent-Over Barbell Row**: 4 sets × 6-10 reps *(Builds overall back thickness, rhomboids & mid-traps)*
   - **Pull-Ups / Wide Lat Pulldowns**: 4 sets × 8-12 reps *(Key for lat width & V-taper)*
   - **Seated Cable Row / Chest-Supported T-Bar Row**: 3 sets × 10-12 reps *(Isolates mid-back without lower back fatigue)*
   - **Straight-Arm Cable Pullovers**: 3 sets × 12-15 reps *(Direct lat stretch & isolation)*

2. **Crucial Form & Mind-Muscle Cues**
   - **Initiate with the elbows**: Think of your hands as hooks; drive your elbows down and back toward your hip pockets.
   - **Scapular Retraction**: Squeeze your shoulder blades tightly for 1 second at the peak of every rep.
   - **Controlled Eccentric**: Take 2-3 seconds on the stretch to maximize muscle tension.

3. **Nutrition & Recovery for Back Growth**
   - Fuel with **$minProtein g to $maxProtein g daily protein**. Back is a massive muscle group requiring 48-72 hours of recovery between heavy sessions.
''';
    }

    // 3. LEGS TRAINING & LOWER BODY HYPERTROPHY
    if (query.contains('leg') ||
        query.contains('quad') ||
        query.contains('hamstring') ||
        query.contains('squat') ||
        query.contains('glute') ||
        query.contains('calf') ||
        query.contains('calves')) {
      return '''
### 🦵 OmniFit Complete Leg Training & Hypertrophy Guide

Legs make up over 50% of your skeletal muscle. Here is the ultimate routine for quad sweep, hamstring depth, and calves:

1. **Complete Leg Workout Routine**
   - **Barbell Back / Front Squat**: 4 sets × 6-8 reps *(King of lower body compound growth)*
   - **Romanian Deadlifts (RDLs)**: 4 sets × 8-10 reps *(Essential for hamstring stretch & glute development)*
   - **Bulgarian Split Squats**: 3 sets × 10-12 reps per leg *(Cures muscular imbalances & builds massive quads)*
   - **Leg Press / Walking Lunges**: 3 sets × 12-15 reps *(High volume quad pump)*
   - **Lying or Seated Hamstring Curls**: 3 sets × 12-15 reps *(Knee flexion for hamstrings)*
   - **Standing Calf Raises**: 4 sets × 15-20 reps *(Slow 2s stretch at the bottom)*

2. **Pro Form Guidelines**
   - **Squat Depth**: Aim for thighs at least parallel to the floor; push knees out over toes.
   - **Hips on RDLs**: Push your hips backward as if touching a wall behind you rather than bending over with your lower back.
   - **Progressive Overload**: Legs respond exceptionally well to gradual load increases and deep range of motion.
''';
    }

    // 4. CHEST MUSCLE GROWTH & TRAINING
    if (query.contains('chest') ||
        query.contains('pec') ||
        query.contains('bench press') ||
        query.contains('pushup')) {
      return '''
### 🛡️ OmniFit Chest Hypertrophy Blueprint

For a full, armor-plated chest from upper collarbone to lower pec:

1. **Optimal Chest Workout Routine**
   - **Incline Dumbbell Press (30° Angle)**: 4 sets × 8-10 reps *(Prioritizes clavicular/upper pec head)*
   - **Flat Barbell Bench Press**: 3 sets × 6-8 reps *(Maximum mechanical tension for overall pec mass)*
   - **Weighted or Bodyweight Chest Dips**: 3 sets × 8-12 reps *(Lower pec stretch & tricep drive)*
   - **Cable Crossover / Pec Deck Flyes**: 3 sets × 12-15 reps *(Peak contraction with constant tension)*

2. **Form Tips**
   - Retract and depress your shoulder blades (pinch them together and slide them into your back pockets).
   - Maintain a slight arch and keep your chest puffed out to take stress off your anterior deltoids.
''';
    }

    // 5. SHOULDERS & DELTOIDS
    if (query.contains('shoulder') ||
        query.contains('delt') ||
        query.contains('overhead press') ||
        query.contains('lateral raise')) {
      return '''
### 🥥 OmniFit 3D Shoulder Development Guide

To build round, "cannonball" shoulders, you must train all 3 deltoid heads:

1. **Targeted Shoulder Routine**
   - **Overhead Barbell / Dumbbell Press**: 4 sets × 6-8 reps *(Front delts & core stability)*
   - **Dumbbell / Cable Lateral Raises**: 4 sets × 12-15 reps *(Side delts: creates upper body width)*
   - **Face Pulls or Reverse Pec Deck**: 4 sets × 15-20 reps *(Rear delts: posture, 3D look, shoulder health)*
   - **Dumbbell Shrugs**: 3 sets × 12-15 reps *(Upper traps)*

2. **Pro Tip**: Side and rear delts recover rapidly; train lateral raises 2-3 times per week with strict form without swinging.
''';
    }

    // 6. ARMS (BICEPS & TRICEPS)
    if (query.contains('arm') ||
        query.contains('bicep') ||
        query.contains('tricep') ||
        query.contains('curl')) {
      return '''
### 💪 OmniFit Arm Hypertrophy Protocol

Triceps make up ~60% of upper arm size, while biceps give the round peak:

1. **Tricep Mass Builders (Heavy Push)**
   - **Close-Grip Bench Press or Skullcrushers**: 3 sets × 8-10 reps
   - **Overhead Cable Rope Extension**: 3 sets × 12 reps *(Stretches the long head of the tricep)*
   - **Cable Straight-Bar Pushdown**: 3 sets × 12-15 reps *(Lateral tricep head lockout)*

2. **Bicep Mass Builders (Strict Pull)**
   - **Standing Barbell Curl**: 3 sets × 8-10 reps *(Overall bicep overload)*
   - **Incline Dumbbell Curl**: 3 sets × 10-12 reps *(Stretches long head for greater peak)*
   - **Dumbbell Hammer Curl**: 3 sets × 10-12 reps *(Brachialis & forearm thickness)*
''';
    }

    // 7. GENERAL MUSCLE GROWTH / HYPERTROPHY
    if (query.contains('muscle') ||
        query.contains('hypertrophy') ||
        query.contains('growth') ||
        query.contains('gains')) {
      return '''
### 🏋️ OmniFit Blueprint for Maximum Muscle Growth

To trigger optimal muscle hypertrophy across your whole physique:

1. **Progressive Overload (The Golden Rule)**
   - Aim to add **1-2 repetitions** or slightly increase weight (1-2.5 kg) on compound lifts every 1-2 weeks.
   - Optimal hypertrophy rep range: **6 to 12 reps** within 1-3 reps of muscular failure (RIR 1-2).

2. **Protein Target for Your Weight ($weight kg)**
   - Aim for **$minProtein g to $maxProtein g of protein daily** (~1.8-2.0g per kg).
   - Distribute across 3-5 meals (30-40g protein per feeding) to maximize muscle protein synthesis.

3. **Optimal Training Volume & Frequency**
   - Hit each major muscle group **2 times per week** with 10-18 total challenging sets weekly.
   - Example splits: **Push-Pull-Legs (PPL)** or **Upper / Lower**.

4. **Caloric Surplus**
   - Consume a mild surplus of **+250 to +400 calories** above maintenance for clean, lean tissue gains without excessive fat.
''';
    }

    // 3. WEIGHT LOSS / FAT LOSS / CUTTING
    if (query.contains('lose') ||
        query.contains('fat') ||
        query.contains('cut') ||
        query.contains('belly') ||
        query.contains('slimming') ||
        query.contains('deficit')) {
      return '''
### 🔥 OmniFit Strategy for Sustainable Fat Loss

Here is how to strip body fat while preserving your hard-earned muscle:

1. **Calculated Caloric Deficit**
   - Aim for a moderate deficit of **300 to 500 calories** below your Total Daily Energy Expenditure (TDEE).
   - Target weight loss rate: **0.5% to 1.0% of your body weight per week** (~0.4-0.8 kg) to prevent muscle loss.

2. **High-Protein Satiety Shield**
   - Keep protein high at **1.8 - 2.2g per kg** of bodyweight ($weight kg ≈ ${(weight * 2.0).round()}g protein).
   - High protein keeps you full, preserves lean muscle, and burns more calories during digestion (TEF).

3. **Resistance Training Over Endless Cardio**
   - Continue lifting weights 3-4 days weekly. Strength training signals your body to burn fat instead of muscle tissue.
   - Pair with **8,000 - 10,000 daily steps** (NEAT) for low-stress caloric burn.

4. **Volume Eating**
   - Fill 50% of your plate with high-volume, low-calorie foods: green leafy vegetables, cucumber, zucchini, and berries.
''';
    }

    // 4. WEIGHT GAIN / BULKING / HARDGAINER
    if (query.contains('gain') ||
        query.contains('bulk') ||
        query.contains('skinny') ||
        query.contains('underweight') ||
        query.contains('hardgainer')) {
      final targetCalories = (weight * 36).round() + 350;

      return '''
### 📈 OmniFit Lean Bulking Protocol

If you are struggling to gain weight or build size, follow this plan:

1. **Daily Caloric Surplus**
   - Target roughly **$targetCalories kcal per day** (~300-500 kcal above maintenance).
   - Weigh yourself every 3 days. Aim to gain **1.0 to 1.5 kg per month** for clean lean mass.

2. **Calorie-Dense Nutrient Sources**
   - If large meals make you too full, add calorie-dense foods:
     * Peanut butter / Almond butter (2 tbsp = ~190 kcal)
     * Oats, whole milk, Greek yogurt, olive oil, and avocados
     * Nuts and seeds (walnuts, almonds, chia seeds)

3. **High-Calorie Homemade Anabolic Shake**
   - Blend: 1 banana, 50g oats, 1 scoop whey protein, 2 tbsp peanut butter, 300ml milk. *(Approx. 650 kcal, 45g protein!)*

4. **Heavy Compound Resistance Training**
   - Focus on Squats, Deadlifts, Bench Press, Overhead Press, and Barbell Rows.
   - Rest 2-3 minutes between heavy sets to maximize strength performance.
''';
    }

    // 5. DIET & MEAL PLANNING
    if (query.contains('diet') ||
        query.contains('eat') ||
        query.contains('meal') ||
        query.contains('breakfast') ||
        query.contains('dinner') ||
        query.contains('protein') ||
        query.contains('macro') ||
        query.contains('food')) {
      return '''
### 🥗 OmniFit Balanced Nutrition & Diet Plan

Here is a powerhouse high-protein meal template designed for athletic performance:

1. **Breakfast (Energizing & High Protein)**
   - 3 whole eggs / egg whites scrambled with spinach + 1 cup oatmeal with berries and a scoop of protein powder (~40g protein).

2. **Lunch (Sustained Energy)**
   - 150g grilled chicken breast (or 150g paneer/tofu for vegetarian) + 1 cup brown rice or sweet potatoes + mixed greens with olive oil (~35g protein).

3. **Pre-Workout Fuel (60-90 mins prior)**
   - 1 banana with 1 tbsp peanut butter or rice cakes with honey for quick glycogen availability.

4. **Post-Workout Recovery (Within 2 hrs)**
   - 1 scoop Whey Protein isolate + 1 serving carbs to replenish glycogen and accelerate recovery.

5. **Dinner (Rest & Repair)**
   - 180g salmon / fish or lentil stew (dal) + steamed broccoli and quinoa (~35g protein).
''';
    }

    // 6. WORKOUT ROUTINE & SPLIT
    if (query.contains('routine') ||
        query.contains('split') ||
        query.contains('plan') ||
        query.contains('beginner') ||
        query.contains('schedule') ||
        query.contains('exercise')) {
      return '''
### 🗓️ Recommended OmniFit Training Splits

Choose the routine that matches your weekly schedule:

- **Option A: 3 Days/Week (Full Body)**
  * Best for beginners or busy schedules.
  * *Mon / Wed / Fri*: Squat, Bench Press, Lat Pulldown/Row, Overhead Press, Core.

- **Option B: 4 Days/Week (Upper / Lower)**
  * Balanced frequency and recovery.
  * *Mon*: Upper A (Chest, Back, Arms)
  * *Tue*: Lower A (Quads, Hamstrings, Calves)
  * *Thu*: Upper B (Shoulders, Upper Back, Chest)
  * *Fri*: Lower B (Deadlifts, Glutes, Hamstrings)

- **Option C: 5-6 Days/Week (Push-Pull-Legs - PPL)**
  * High-volume bodybuilding split:
  * *Push*: Chest, Shoulders, Triceps
  * *Pull*: Back, Biceps, Rear Delts
  * *Legs*: Quads, Hamstrings, Calves, Abs

👉 *Tip: You can select exercises and save your exact routine directly in the OmniFit **Strength tab -> Create Plan**!*
''';
    }

    // 7. SUPPLEMENTS
    if (query.contains('creatine') ||
        query.contains('supplement') ||
        query.contains('whey') ||
        query.contains('bcaa') ||
        query.contains('pre workout')) {
      return '''
### 🧪 OmniFit Evidence-Based Supplement Guide

Only a few supplements have extensive scientific backing:

1. **Creatine Monohydrate (Tier 1 - Highly Recommended)**
   - Increases intracellular ATP for strength, power output, and muscle fullness.
   - Dose: **3-5 grams daily** consistently at any time of day. No loading phase necessary.

2. **Whey Protein (Tier 1 - Practical)**
   - Convenient, rapidly digested protein source to easily hit daily targets.
   - Use 1 scoop (25g protein) post-workout or between meals.

3. **Caffeine / Pre-Workout (Optional)**
   - 150-200mg taken 30-45 minutes before training improves focus, power, and reduces perceived exertion.

4. **Vitamin D3 & Omega-3 Fish Oil**
   - Supports hormonal health, joint recovery, and overall immune function.
''';
    }

    // Default general fitness greeting
    return '''
### 👋 Hello Athlete! I am your OmniFit AI Coach

I am here to help you conquer your fitness and physique goals! You can ask me anything about:

- **Diet & Nutrition**: High-protein meals, calculating your calorie needs, macro splits.
- **Muscle Growth**: Progressive overload, best exercises for chest, back, arms, or legs.
- **Weight Management**: Sustainable fat loss protocols or clean lean bulking strategies.
- **Workout Routine**: Designing custom splits (PPL, Upper/Lower, Full Body).
- **Supplements**: Creatine, whey protein, and pre-workout advice.

What would you like to improve or dial in today?
''';
  }
}
