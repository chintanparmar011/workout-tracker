import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/exercise_model.dart';
import '../utils/api_constants.dart';

class ExerciseService {
  static final ExerciseService _instance = ExerciseService._internal();
  factory ExerciseService() => _instance;
  ExerciseService._internal();

  // In-memory cache by category / query
  final Map<String, List<ExerciseModel>> _cache = {};

  /// Fetch exercises for a specific muscle group.
  /// First tries ExerciseDB API if API key is provided,
  /// then falls back to curated database smoothly.
  Future<List<ExerciseModel>> getExercisesByMuscleGroup(String muscleGroup) async {
    final key = muscleGroup.toLowerCase();
    if (_cache.containsKey(key) && _cache[key]!.isNotEmpty) {
      return _cache[key]!;
    }

    if (ApiConstants.exerciseDbApiKey.isNotEmpty) {
      try {
        final endpoint = _getEndpointForMuscle(muscleGroup);
        final url = Uri.parse('${ApiConstants.exerciseDbBaseUrl}$endpoint');
        final response = await http.get(
          url,
          headers: {
            'X-RapidAPI-Key': ApiConstants.exerciseDbApiKey,
            'X-RapidAPI-Host': ApiConstants.exerciseDbHost,
          },
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          final exercises = data
              .take(30)
              .map((json) => ExerciseModel.fromExerciseDbJson(json as Map<String, dynamic>))
              .toList();

          if (exercises.isNotEmpty) {
            _cache[key] = exercises;
            return exercises;
          }
        }
      } catch (_) {
        // Fallback below
      }
    }

    // Fallback to rich curated exercise catalog
    final fallbackList = _getCuratedExercises(muscleGroup);
    _cache[key] = fallbackList;
    return fallbackList;
  }

  /// Search exercises across API and curated catalog
  Future<List<ExerciseModel>> searchExercises(String query) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return [];

    if (ApiConstants.exerciseDbApiKey.isNotEmpty) {
      try {
        final url = Uri.parse(
          '${ApiConstants.exerciseDbBaseUrl}/exercises/name/${Uri.encodeComponent(clean)}',
        );
        final response = await http.get(
          url,
          headers: {
            'X-RapidAPI-Key': ApiConstants.exerciseDbApiKey,
            'X-RapidAPI-Host': ApiConstants.exerciseDbHost,
          },
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          final list = data
              .take(25)
              .map((json) => ExerciseModel.fromExerciseDbJson(json as Map<String, dynamic>))
              .toList();
          if (list.isNotEmpty) return list;
        }
      } catch (_) {
        // Fallback below
      }
    }

    // Search in curated catalog
    final all = getAllCuratedExercises();
    return all.where((e) {
      return e.name.toLowerCase().contains(clean) ||
          e.muscleGroup.toLowerCase().contains(clean) ||
          e.equipment.toLowerCase().contains(clean);
    }).toList();
  }

  /// Lookup exercise by ID
  Future<ExerciseModel?> getExerciseById(String id) async {
    final all = getAllCuratedExercises();
    final match = all.firstWhere((e) => e.id == id, orElse: () => _emptyExercise);
    if (match.id.isNotEmpty) return match;

    // Check in-memory cache
    for (final list in _cache.values) {
      for (final e in list) {
        if (e.id == id) return e;
      }
    }

    return null;
  }

  static final ExerciseModel _emptyExercise = ExerciseModel(
    id: '',
    name: '',
    description: '',
    muscleGroup: '',
    difficulty: '',
    equipment: '',
    targetSets: 0,
    targetReps: 0,
    restSeconds: 0,
    instructions: '',
  );

  String _getEndpointForMuscle(String muscleGroup) {
    switch (muscleGroup.toLowerCase()) {
      case 'chest':
        return '/exercises/bodyPart/chest?limit=25';
      case 'back':
        return '/exercises/bodyPart/back?limit=25';
      case 'shoulders':
        return '/exercises/bodyPart/shoulders?limit=25';
      case 'biceps':
        return '/exercises/target/biceps?limit=25';
      case 'triceps':
        return '/exercises/target/triceps?limit=25';
      case 'legs':
        return '/exercises/bodyPart/upper%20legs?limit=25';
      case 'abs/core':
      case 'abs':
      case 'core':
        return '/exercises/bodyPart/waist?limit=25';
      default:
        return '/exercises?limit=25';
    }
  }

  /// Curated database covering all 7 standard muscle groups
  List<ExerciseModel> _getCuratedExercises(String muscleGroup) {
    final norm = muscleGroup.toLowerCase();
    return getAllCuratedExercises().where((e) {
      return e.muscleGroup.toLowerCase() == norm ||
          (norm.contains('abs') && e.muscleGroup.toLowerCase().contains('abs'));
    }).toList();
  }

  List<ExerciseModel> getAllCuratedExercises() {
    return [
      // ==========================================
      // --- CHEST (10 Premier Exercises) ---
      // ==========================================
      ExerciseModel(
        id: 'bench_press01',
        name: 'Barbell Bench Press',
        description: 'Primary strength builder for pectoral development and upper body pushing power.',
        muscleGroup: 'Chest',
        difficulty: 'intermediate',
        equipment: 'Barbell & Bench',
        targetSets: 4,
        targetReps: 10,
        restSeconds: 90,
        instructions: '1. Lie on flat bench, grip barbell slightly wider than shoulder-width.\n2. Unrack and lower bar smoothly to mid-chest.\n3. Drive feet into floor and press upward.',
      ),
      ExerciseModel(
        id: 'incline_db_press01',
        name: 'Incline Dumbbell Press',
        description: 'Emphasizes the clavicular head (upper chest) and provides deep stretch.',
        muscleGroup: 'Chest',
        difficulty: 'intermediate',
        equipment: 'Dumbbells & Incline Bench',
        targetSets: 4,
        targetReps: 10,
        restSeconds: 75,
        instructions: '1. Set bench to 30-45 degrees.\n2. Press dumbbells straight up from shoulder level.\n3. Lower slowly until elbows reach 90 degrees.',
      ),
      ExerciseModel(
        id: 'decline_bench_press01',
        name: 'Decline Barbell Press',
        description: 'Targets lower chest fibers with reduced shoulder joint stress.',
        muscleGroup: 'Chest',
        difficulty: 'intermediate',
        equipment: 'Barbell & Decline Bench',
        targetSets: 3,
        targetReps: 10,
        restSeconds: 75,
        instructions: '1. Secure legs on decline bench.\n2. Lower bar to lower chest.\n3. Press firmly upward.',
      ),
      ExerciseModel(
        id: 'pushup01',
        name: 'Standard Push-Ups',
        description: 'Classic bodyweight compound movement targeting the chest, shoulders, and triceps.',
        muscleGroup: 'Chest',
        difficulty: 'beginner',
        equipment: 'Bodyweight',
        targetSets: 3,
        targetReps: 15,
        restSeconds: 60,
        instructions: '1. Place hands slightly wider than shoulder-width.\n2. Keep core tight and body in a straight line.\n3. Lower chest to floor and press back up.',
      ),
      ExerciseModel(
        id: 'incline_pushup01',
        name: 'Incline Push-Ups',
        description: 'Elevated push-up focusing on lower chest and easier rep execution.',
        muscleGroup: 'Chest',
        difficulty: 'beginner',
        equipment: 'Bench or Elevation',
        targetSets: 3,
        targetReps: 12,
        restSeconds: 60,
        instructions: '1. Place hands on elevated bench.\n2. Lower chest towards edge of bench.\n3. Push firmly back to starting position.',
      ),
      ExerciseModel(
        id: 'diamond_pushup01',
        name: 'Diamond Push-Ups',
        description: 'Close-grip push-up emphasizing inner chest and tricep contraction.',
        muscleGroup: 'Chest',
        difficulty: 'intermediate',
        equipment: 'Bodyweight',
        targetSets: 3,
        targetReps: 12,
        restSeconds: 60,
        instructions: '1. Place thumbs and index fingers together forming a diamond.\n2. Lower chest to hands with elbows tucked.\n3. Push up powerfully.',
      ),
      ExerciseModel(
        id: 'dumbbell_fly01',
        name: 'Dumbbell Chest Fly',
        description: 'Isolation exercise emphasizing the stretch and squeeze of pectoral fibers.',
        muscleGroup: 'Chest',
        difficulty: 'intermediate',
        equipment: 'Dumbbells & Bench',
        targetSets: 3,
        targetReps: 12,
        restSeconds: 60,
        instructions: '1. Lie flat with dumbbells extended above chest.\n2. With elbows slightly bent, open arms in an arc.\n3. Squeeze chest to return dumbbells to top.',
      ),
      ExerciseModel(
        id: 'cable_crossover01',
        name: 'Cable Crossover',
        description: 'Constant tension movement for chest definition and inner pec squeeze.',
        muscleGroup: 'Chest',
        difficulty: 'intermediate',
        equipment: 'Cable Machine',
        targetSets: 3,
        targetReps: 15,
        restSeconds: 60,
        instructions: '1. Set pulleys at shoulder height or high.\n2. Step forward and bring handles together in front of chest in a hugging motion.\n3. Squeeze hard for 1 second.',
      ),
      ExerciseModel(
        id: 'dips_chest01',
        name: 'Chest Dips',
        description: 'Bodyweight powerhouse for lower pec sweep and anterior deltoid strength.',
        muscleGroup: 'Chest',
        difficulty: 'intermediate',
        equipment: 'Dip Station',
        targetSets: 3,
        targetReps: 10,
        restSeconds: 75,
        instructions: '1. Lean torso forward ~30 degrees.\n2. Lower until shoulders are below elbows.\n3. Push back up focusing on chest squeeze.',
      ),
      ExerciseModel(
        id: 'machine_chest_press01',
        name: 'Machine Chest Press',
        description: 'Safe, guided compound pressing machine ideal for high intensity and drop sets.',
        muscleGroup: 'Chest',
        difficulty: 'beginner',
        equipment: 'Chest Press Machine',
        targetSets: 3,
        targetReps: 12,
        restSeconds: 60,
        instructions: '1. Adjust seat height so handles align with mid-chest.\n2. Press handles outward.\n3. Return slowly without clanking weights.',
      ),

      // ==========================================
      // --- BACK (10 Premier Exercises) ---
      // ==========================================
      ExerciseModel(
        id: 'deadlift01',
        name: 'Conventional Barbell Deadlift',
        description: 'Ultimate full-body compound pulling movement building total posterior chain strength.',
        muscleGroup: 'Back',
        difficulty: 'advanced',
        equipment: 'Barbell',
        targetSets: 4,
        targetReps: 6,
        restSeconds: 120,
        instructions: '1. Stand with mid-foot under barbell.\n2. Hinge hips back, grip bar with straight arms.\n3. Drive through heels, pull hips forward to lockout.',
      ),
      ExerciseModel(
        id: 'pullup01',
        name: 'Pull-Ups',
        description: 'Essential vertical pulling movement for lat width and grip strength.',
        muscleGroup: 'Back',
        difficulty: 'intermediate',
        equipment: 'Pull-Up Bar',
        targetSets: 3,
        targetReps: 8,
        restSeconds: 90,
        instructions: '1. Overhand grip slightly wider than shoulders.\n2. Pull elbows down towards ribcage until chin clears bar.\n3. Lower with control.',
      ),
      ExerciseModel(
        id: 'chinup01',
        name: 'Chin-Ups',
        description: 'Underhand vertical pull activating lower lats and biceps heavily.',
        muscleGroup: 'Back',
        difficulty: 'intermediate',
        equipment: 'Pull-Up Bar',
        targetSets: 3,
        targetReps: 8,
        restSeconds: 90,
        instructions: '1. Palms facing you shoulder-width apart.\n2. Pull body upward until chin is over bar.\n3. Lower smoothly all the way down.',
      ),
      ExerciseModel(
        id: 'barbell_row01',
        name: 'Bent-Over Barbell Row',
        description: 'Compound pulling exercise building back thickness, rhomboids, and rear delts.',
        muscleGroup: 'Back',
        difficulty: 'intermediate',
        equipment: 'Barbell',
        targetSets: 4,
        targetReps: 10,
        restSeconds: 75,
        instructions: '1. Hinge at hips with flat back.\n2. Pull bar toward lower ribs.\n3. Squeeze shoulder blades together at top.',
      ),
      ExerciseModel(
        id: 'lat_pulldown01',
        name: 'Lat Pulldown',
        description: 'Cable movement targeting latissimus dorsi with controlled resistance.',
        muscleGroup: 'Back',
        difficulty: 'beginner',
        equipment: 'Cable Machine',
        targetSets: 3,
        targetReps: 12,
        restSeconds: 60,
        instructions: '1. Sit upright, grip wide bar.\n2. Pull bar down towards upper chest.\n3. Slowly let bar rise back up.',
      ),
      ExerciseModel(
        id: 'seated_cable_row01',
        name: 'Seated Cable Row',
        description: 'Horizonal cable row targeting mid-back, rhomboids, and lats.',
        muscleGroup: 'Back',
        difficulty: 'beginner',
        equipment: 'Cable Row Machine',
        targetSets: 4,
        targetReps: 10,
        restSeconds: 60,
        instructions: '1. Sit with knees slightly bent, back straight.\n2. Pull V-handle into abdomen.\n3. Retract shoulder blades, pause, and return with control.',
      ),
      ExerciseModel(
        id: 'one_arm_db_row01',
        name: 'One-Arm Dumbbell Row',
        description: 'Unilateral back builder allowing maximum range of motion and lat stretch.',
        muscleGroup: 'Back',
        difficulty: 'intermediate',
        equipment: 'Dumbbell & Bench',
        targetSets: 3,
        targetReps: 10,
        restSeconds: 60,
        instructions: '1. Place knee and hand on flat bench.\n2. Pull dumbbell toward hip with elbow close to body.\n3. Lower with deep stretch.',
      ),
      ExerciseModel(
        id: 't_bar_row01',
        name: 'T-Bar Row',
        description: 'Heavy compound row providing intense middle back and trap thickness.',
        muscleGroup: 'Back',
        difficulty: 'intermediate',
        equipment: 'T-Bar Machine or Landmine',
        targetSets: 4,
        targetReps: 10,
        restSeconds: 75,
        instructions: '1. Straddle bar with chest supported or hips hinged.\n2. Pull handles to chest.\n3. Squeeze scapulae at top of rep.',
      ),
      ExerciseModel(
        id: 'face_pull01',
        name: 'Face Pulls',
        description: 'Vital shoulder health and upper back builder for rear delts and rotators.',
        muscleGroup: 'Back',
        difficulty: 'beginner',
        equipment: 'Cable Machine & Rope',
        targetSets: 3,
        targetReps: 15,
        restSeconds: 45,
        instructions: '1. Set rope pulley at eye level.\n2. Pull towards forehead, rotating hands outward.\n3. Squeeze upper back and external rotators.',
      ),
      ExerciseModel(
        id: 'straight_arm_pulldown01',
        name: 'Straight-Arm Cable Pulldown',
        description: 'Lat isolation movement keeping biceps disengaged for pure lat activation.',
        muscleGroup: 'Back',
        difficulty: 'beginner',
        equipment: 'Cable Machine & Bar',
        targetSets: 3,
        targetReps: 12,
        restSeconds: 60,
        instructions: '1. Stand with arms extended holding bar at forehead height.\n2. Keeping elbows nearly straight, sweep bar down to thighs.\n3. Squeeze lats hard at bottom.',
      ),

      // ==========================================
      // --- SHOULDERS (10 Premier Exercises) ---
      // ==========================================
      ExerciseModel(
        id: 'overhead_press01',
        name: 'Overhead Barbell Shoulder Press',
        description: 'Core vertical pressing movement for anterior deltoids and triceps.',
        muscleGroup: 'Shoulders',
        difficulty: 'intermediate',
        equipment: 'Barbell or Dumbbells',
        targetSets: 4,
        targetReps: 8,
        restSeconds: 90,
        instructions: '1. Stand tall with weights at shoulder height.\n2. Press straight overhead without arching lower back.\n3. Lock out arms, then lower with control.',
      ),
      ExerciseModel(
        id: 'db_shoulder_press01',
        name: 'Seated Dumbbell Shoulder Press',
        description: 'Overhead pressing with independent dumbbell control and balanced delt loading.',
        muscleGroup: 'Shoulders',
        difficulty: 'intermediate',
        equipment: 'Dumbbells & Bench',
        targetSets: 4,
        targetReps: 10,
        restSeconds: 75,
        instructions: '1. Sit on upright bench holding dumbbells at shoulders.\n2. Press upward until arms are extended overhead.\n3. Lower with controlled descent.',
      ),
      ExerciseModel(
        id: 'lateral_raise01',
        name: 'Dumbbell Lateral Raise',
        description: 'Crucial isolation movement for building shoulder width and lateral delts.',
        muscleGroup: 'Shoulders',
        difficulty: 'beginner',
        equipment: 'Dumbbells',
        targetSets: 4,
        targetReps: 15,
        restSeconds: 45,
        instructions: '1. Hold dumbbells at sides.\n2. Raise arms out laterally to shoulder height with slight elbow bend.\n3. Lower slowly.',
      ),
      ExerciseModel(
        id: 'cable_lateral_raise01',
        name: 'Cable Lateral Raise',
        description: 'Constant tension isolation for side deltoid capped width.',
        muscleGroup: 'Shoulders',
        difficulty: 'intermediate',
        equipment: 'Cable Machine',
        targetSets: 3,
        targetReps: 15,
        restSeconds: 45,
        instructions: '1. Set low pulley, hold single handle across body.\n2. Raise arm outward to shoulder level.\n3. Control the descent.',
      ),
      ExerciseModel(
        id: 'front_plate_raise01',
        name: 'Weight Plate Front Raise',
        description: 'Isolates anterior deltoid head with steady grip control.',
        muscleGroup: 'Shoulders',
        difficulty: 'beginner',
        equipment: 'Weight Plate',
        targetSets: 3,
        targetReps: 12,
        restSeconds: 45,
        instructions: '1. Hold weight plate with both hands at hip level.\n2. Raise plate smoothly to eye level.\n3. Pause and lower slowly.',
      ),
      ExerciseModel(
        id: 'rear_delt_fly01',
        name: 'Dumbbell Rear Delt Fly',
        description: 'Builds rear shoulder thickness and balances anterior posture.',
        muscleGroup: 'Shoulders',
        difficulty: 'beginner',
        equipment: 'Dumbbells',
        targetSets: 3,
        targetReps: 15,
        restSeconds: 45,
        instructions: '1. Hinge forward at hips with flat back.\n2. Raise dumbbells out to sides squeezing shoulder blades.\n3. Lower under control.',
      ),
      ExerciseModel(
        id: 'arnold_press01',
        name: 'Arnold Dumbbell Press',
        description: 'Rotational shoulder press engaging front, side, and rear delt heads.',
        muscleGroup: 'Shoulders',
        difficulty: 'intermediate',
        equipment: 'Dumbbells',
        targetSets: 3,
        targetReps: 10,
        restSeconds: 60,
        instructions: '1. Hold dumbbells at chest with palms facing you.\n2. Rotate palms outward as you press overhead.\n3. Reverse rotation on descent.',
      ),
      ExerciseModel(
        id: 'upright_row01',
        name: 'Barbell Upright Row',
        description: 'Compound lift hitting lateral deltoids and upper trapezius simultaneously.',
        muscleGroup: 'Shoulders',
        difficulty: 'intermediate',
        equipment: 'Barbell or EZ-Bar',
        targetSets: 3,
        targetReps: 12,
        restSeconds: 60,
        instructions: '1. Grip bar shoulder-width apart.\n2. Pull bar up to chest leading with elbows.\n3. Lower with smooth tempo.',
      ),
      ExerciseModel(
        id: 'barbell_shrug01',
        name: 'Barbell Shrugs',
        description: 'Heavy overload exercise targeting the upper trapezius neck muscles.',
        muscleGroup: 'Shoulders',
        difficulty: 'beginner',
        equipment: 'Barbell',
        targetSets: 4,
        targetReps: 12,
        restSeconds: 60,
        instructions: '1. Hold barbell with overhand grip in front of thighs.\n2. Elevate shoulders straight up towards ears.\n3. Squeeze traps at top and lower.',
      ),
      ExerciseModel(
        id: 'dumbbell_shrug01',
        name: 'Dumbbell Shrugs',
        description: 'Neutral grip shrug allowing natural wrist positioning and deep trap stretch.',
        muscleGroup: 'Shoulders',
        difficulty: 'beginner',
        equipment: 'Dumbbells',
        targetSets: 3,
        targetReps: 15,
        restSeconds: 45,
        instructions: '1. Hold heavy dumbbells at sides.\n2. Shrug shoulders upward without rolling shoulders.\n3. Pause 1 second at top and lower.',
      ),

      // ==========================================
      // --- BICEPS (8 Premier Exercises) ---
      // ==========================================
      ExerciseModel(
        id: 'bicep_curl01',
        name: 'Dumbbell Bicep Curl',
        description: 'Classic arm builder emphasizing biceps peak and forearm control.',
        muscleGroup: 'Biceps',
        difficulty: 'beginner',
        equipment: 'Dumbbells',
        targetSets: 3,
        targetReps: 12,
        restSeconds: 60,
        instructions: '1. Stand upright with dumbbells at sides, palms forward.\n2. Curl weights while keeping elbows pinned to ribs.\n3. Squeeze biceps at peak and lower slowly.',
      ),
      ExerciseModel(
        id: 'barbell_curl01',
        name: 'Barbell Bicep Curl',
        description: 'Heavy bilateral bicep mass builder for overall arm thickness.',
        muscleGroup: 'Biceps',
        difficulty: 'intermediate',
        equipment: 'Barbell or EZ-Bar',
        targetSets: 4,
        targetReps: 10,
        restSeconds: 60,
        instructions: '1. Grip bar shoulder-width, palms supinated.\n2. Curl bar toward upper chest without swinging torso.\n3. Lower under strict control.',
      ),
      ExerciseModel(
        id: 'hammer_curl01',
        name: 'Hammer Curls',
        description: 'Neutral-grip curl emphasizing brachialis and forearm thickness.',
        muscleGroup: 'Biceps',
        difficulty: 'beginner',
        equipment: 'Dumbbells',
        targetSets: 3,
        targetReps: 12,
        restSeconds: 60,
        instructions: '1. Hold dumbbells with palms facing each other.\n2. Curl upward keeping wrists neutral.\n3. Lower with steady control.',
      ),
      ExerciseModel(
        id: 'incline_db_curl01',
        name: 'Incline Dumbbell Curl',
        description: 'Positions the arm behind the torso for maximum long head bicep stretch.',
        muscleGroup: 'Biceps',
        difficulty: 'intermediate',
        equipment: 'Dumbbells & Incline Bench',
        targetSets: 3,
        targetReps: 10,
        restSeconds: 60,
        instructions: '1. Sit on 45-60 degree incline bench with arms hanging down.\n2. Curl dumbbells upward with full supination.\n3. Lower slowly enjoying the deep stretch.',
      ),
      ExerciseModel(
        id: 'preacher_curl01',
        name: 'Preacher Curl',
        description: 'Eliminates momentum to isolate the short head bicep peak.',
        muscleGroup: 'Biceps',
        difficulty: 'intermediate',
        equipment: 'Preacher Bench & EZ-Bar',
        targetSets: 3,
        targetReps: 12,
        restSeconds: 60,
        instructions: '1. Rest upper arms securely against preacher pad.\n2. Curl bar upward until forearms are vertical.\n3. Lower slowly without locking elbows at bottom.',
      ),
      ExerciseModel(
        id: 'cable_rope_curl01',
        name: 'Cable Rope Hammer Curl',
        description: 'Constant resistance hammer curl challenging brachialis throughout range.',
        muscleGroup: 'Biceps',
        difficulty: 'beginner',
        equipment: 'Cable Machine & Rope',
        targetSets: 3,
        targetReps: 15,
        restSeconds: 45,
        instructions: '1. Attach rope to low pulley, hold with neutral grip.\n2. Curl upward, pulling ends outward slightly at top.\n3. Lower smoothly.',
      ),
      ExerciseModel(
        id: 'concentration_curl01',
        name: 'Concentration Curl',
        description: 'Seated isolation curl maximizing mind-muscle connection and peak contraction.',
        muscleGroup: 'Biceps',
        difficulty: 'beginner',
        equipment: 'Dumbbell & Bench',
        targetSets: 3,
        targetReps: 12,
        restSeconds: 45,
        instructions: '1. Sit on bench, brace elbow against inner thigh.\n2. Curl dumbbell toward face.\n3. Squeeze bicep firmly at peak.',
      ),
      ExerciseModel(
        id: 'ez_bar_21s01',
        name: 'EZ-Bar Bicep 21s',
        description: 'Intense hypertrophy finisher: 7 bottom half, 7 top half, 7 full range reps.',
        muscleGroup: 'Biceps',
        difficulty: 'advanced',
        equipment: 'EZ-Bar',
        targetSets: 3,
        targetReps: 21,
        restSeconds: 90,
        instructions: '1. Perform 7 reps from bottom to 90 degrees.\n2. Perform 7 reps from 90 degrees to top.\n3. Finish with 7 full range of motion reps.',
      ),

      // ==========================================
      // --- TRICEPS (8 Premier Exercises) ---
      // ==========================================
      ExerciseModel(
        id: 'cable_pushdown01',
        name: 'Tricep Rope Pushdown',
        description: 'Cable movement for lateral tricep isolation with constant tension.',
        muscleGroup: 'Triceps',
        difficulty: 'beginner',
        equipment: 'Cable Machine & Rope',
        targetSets: 3,
        targetReps: 15,
        restSeconds: 60,
        instructions: '1. Hold rope at chest level, elbows tucked.\n2. Push down and spread ends of rope apart at the bottom.\n3. Control return upward.',
      ),
      ExerciseModel(
        id: 'skull_crushers01',
        name: 'Lying Tricep Skull Crushers',
        description: 'Staple mass builder targeting the long head of the triceps.',
        muscleGroup: 'Triceps',
        difficulty: 'intermediate',
        equipment: 'EZ-Bar & Flat Bench',
        targetSets: 4,
        targetReps: 10,
        restSeconds: 75,
        instructions: '1. Lie on bench holding bar above shoulders.\n2. Hinge at elbows, lowering bar towards forehead/crown.\n3. Extend elbows back to lockout.',
      ),
      ExerciseModel(
        id: 'close_grip_bench01',
        name: 'Close-Grip Barbell Bench Press',
        description: 'Heavy compound movement placing tremendous mechanical tension on triceps.',
        muscleGroup: 'Triceps',
        difficulty: 'intermediate',
        equipment: 'Barbell & Bench',
        targetSets: 4,
        targetReps: 8,
        restSeconds: 90,
        instructions: '1. Grip bar with hands shoulder-width apart.\n2. Lower bar to lower chest keeping elbows tucked.\n3. Press powerfully up.',
      ),
      ExerciseModel(
        id: 'overhead_db_tricep01',
        name: 'Overhead Dumbbell Tricep Extension',
        description: 'Full stretch movement maximizing long head tricep hypertrophy.',
        muscleGroup: 'Triceps',
        difficulty: 'intermediate',
        equipment: 'Dumbbell & Seat',
        targetSets: 3,
        targetReps: 12,
        restSeconds: 60,
        instructions: '1. Hold dumbbell overhead with both hands forming a cup.\n2. Lower dumbbell behind head keeping elbows forward.\n3. Extend arms back overhead.',
      ),
      ExerciseModel(
        id: 'tricep_dips01',
        name: 'Bench Tricep Dips',
        description: 'Bodyweight triceps builder targeting all three tricep heads.',
        muscleGroup: 'Triceps',
        difficulty: 'beginner',
        equipment: 'Bench or Chair',
        targetSets: 3,
        targetReps: 12,
        restSeconds: 60,
        instructions: '1. Place hands on edge of bench behind back.\n2. Lower hips until elbows reach 90-degree angle.\n3. Push firmly through palms back to top.',
      ),
      ExerciseModel(
        id: 'cable_overhead_tricep01',
        name: 'Cable Overhead Rope Extension',
        description: 'Continuous cable tension throughout extreme tricep stretch.',
        muscleGroup: 'Triceps',
        difficulty: 'intermediate',
        equipment: 'Cable Machine & Rope',
        targetSets: 3,
        targetReps: 12,
        restSeconds: 60,
        instructions: '1. Facing away from low or medium pulley, extend arms overhead.\n2. Flex elbows behind head.\n3. Extend arms forward and flare rope ends.',
      ),
      ExerciseModel(
        id: 'tricep_kickback01',
        name: 'Dumbbell Tricep Kickback',
        description: 'Peak contraction isolation exercise for lateral and medial tricep heads.',
        muscleGroup: 'Triceps',
        difficulty: 'beginner',
        equipment: 'Dumbbell & Bench',
        targetSets: 3,
        targetReps: 15,
        restSeconds: 45,
        instructions: '1. Hinge torso forward with upper arm parallel to floor.\n2. Extend forearm backward until arm is straight.\n3. Squeeze tricep for 1 second, then return.',
      ),
      ExerciseModel(
        id: 'straight_bar_pushdown01',
        name: 'Straight Bar Tricep Pushdown',
        description: 'Overload pushdown allowing heavier weights on lateral triceps.',
        muscleGroup: 'Triceps',
        difficulty: 'beginner',
        equipment: 'Cable Machine & Straight Bar',
        targetSets: 3,
        targetReps: 12,
        restSeconds: 60,
        instructions: '1. Grip straight bar with overhand grip.\n2. Push down to thighs with locked elbows.\n3. Control the return to chest level.',
      ),

      // ==========================================
      // --- LEGS (12 Premier Exercises) ---
      // ==========================================
      ExerciseModel(
        id: 'barbell_squat01',
        name: 'Barbell Back Squat',
        description: 'The king of lower body exercises for strength and hypertrophy.',
        muscleGroup: 'Legs',
        difficulty: 'intermediate',
        equipment: 'Barbell & Squat Rack',
        targetSets: 4,
        targetReps: 8,
        restSeconds: 120,
        instructions: '1. Rest barbell comfortably across upper traps.\n2. Descend with chest high and knees tracking over toes.\n3. Explosively drive back upward through heels.',
      ),
      ExerciseModel(
        id: 'front_squat01',
        name: 'Barbell Front Squat',
        description: 'Quad-dominant squat maintaining upright posture and core bracing.',
        muscleGroup: 'Legs',
        difficulty: 'advanced',
        equipment: 'Barbell & Squat Rack',
        targetSets: 4,
        targetReps: 8,
        restSeconds: 90,
        instructions: '1. Rack bar across front deltoids with elbows high.\n2. Squat down keeping torso strictly vertical.\n3. Drive up through midfoot.',
      ),
      ExerciseModel(
        id: 'romanian_deadlift01',
        name: 'Romanian Deadlift (RDL)',
        description: 'Premier hamstring and glute builder focusing on the eccentric hip hinge.',
        muscleGroup: 'Legs',
        difficulty: 'intermediate',
        equipment: 'Barbell or Dumbbells',
        targetSets: 4,
        targetReps: 10,
        restSeconds: 90,
        instructions: '1. Hold barbell at thighs with slight knee bend.\n2. Push hips back as bar slides down shins.\n3. Drive hips forward when deep hamstring stretch is felt.',
      ),
      ExerciseModel(
        id: 'leg_press01',
        name: 'Leg Press (45-Degree)',
        description: 'Heavy compound quad and leg builder removing spinal compression.',
        muscleGroup: 'Legs',
        difficulty: 'intermediate',
        equipment: 'Leg Press Machine',
        targetSets: 4,
        targetReps: 12,
        restSeconds: 90,
        instructions: '1. Place feet shoulder-width on platform.\n2. Lower sled until knees reach 90 degrees.\n3. Press up without locking knees at top.',
      ),
      ExerciseModel(
        id: 'bulgarian_split_squat01',
        name: 'Bulgarian Split Squats',
        description: 'Unilateral quad and glute destroyer that balances leg strength.',
        muscleGroup: 'Legs',
        difficulty: 'intermediate',
        equipment: 'Dumbbells & Bench',
        targetSets: 3,
        targetReps: 10,
        restSeconds: 75,
        instructions: '1. Elevate rear foot on bench.\n2. Squat down on front leg until front thigh is parallel to ground.\n3. Drive through front heel to stand.',
      ),
      ExerciseModel(
        id: 'lunges01',
        name: 'Walking Dumbbell Lunges',
        description: 'Unilateral leg builder improving balance, quad activation, and glute strength.',
        muscleGroup: 'Legs',
        difficulty: 'intermediate',
        equipment: 'Dumbbells',
        targetSets: 3,
        targetReps: 12,
        restSeconds: 60,
        instructions: '1. Step forward with one leg, lowering back knee towards floor.\n2. Push through front heel to step into the next lunge.\n3. Alternate legs smoothly.',
      ),
      ExerciseModel(
        id: 'leg_extension01',
        name: 'Leg Extension Machine',
        description: 'Direct quadriceps isolation targeting the rectus femoris and teardrop.',
        muscleGroup: 'Legs',
        difficulty: 'beginner',
        equipment: 'Leg Extension Machine',
        targetSets: 3,
        targetReps: 15,
        restSeconds: 60,
        instructions: '1. Align knee joint with machine axis.\n2. Extend legs to full extension and squeeze quads for 1 second.\n3. Lower with controlled resistance.',
      ),
      ExerciseModel(
        id: 'seated_leg_curl01',
        name: 'Seated Hamstring Leg Curl',
        description: 'Isolates hamstrings in a lengthened hip position for maximum hypertrophy.',
        muscleGroup: 'Legs',
        difficulty: 'beginner',
        equipment: 'Leg Curl Machine',
        targetSets: 3,
        targetReps: 12,
        restSeconds: 60,
        instructions: '1. Adjust thigh pad securely against knees.\n2. Curl legs under thighs as far as possible.\n3. Control the eccentric release.',
      ),
      ExerciseModel(
        id: 'lying_leg_curl01',
        name: 'Lying Hamstring Leg Curl',
        description: 'Prone hamstring curl emphasizing knee flexion and knee stabilizer strength.',
        muscleGroup: 'Legs',
        difficulty: 'beginner',
        equipment: 'Lying Leg Curl Machine',
        targetSets: 3,
        targetReps: 12,
        restSeconds: 60,
        instructions: '1. Lie face down with pad behind ankles.\n2. Curl pad towards glutes.\n3. Lower with smooth tempo.',
      ),
      ExerciseModel(
        id: 'standing_calf_raise01',
        name: 'Standing Calf Raise',
        description: 'Direct gastrocnemius calf builder with full ankle extension and stretch.',
        muscleGroup: 'Legs',
        difficulty: 'beginner',
        equipment: 'Calf Machine or Step',
        targetSets: 4,
        targetReps: 15,
        restSeconds: 45,
        instructions: '1. Ball of foot on ledge, heels hanging off.\n2. Lower heels for a deep 2-second calf stretch.\n3. Push up onto toes as high as possible.',
      ),
      ExerciseModel(
        id: 'seated_calf_raise01',
        name: 'Seated Calf Raise',
        description: 'Targets the soleus muscle located underneath the main calf bellies.',
        muscleGroup: 'Legs',
        difficulty: 'beginner',
        equipment: 'Seated Calf Machine',
        targetSets: 3,
        targetReps: 15,
        restSeconds: 45,
        instructions: '1. Sit with knee pad pressed over lower thighs.\n2. Lower heels fully down, then press up onto balls of feet.\n3. Pause at contraction.',
      ),
      ExerciseModel(
        id: 'goblet_squat01',
        name: 'Goblet Dumbbell Squat',
        description: 'Functional squat pattern promoting deep hip mobility and quad development.',
        muscleGroup: 'Legs',
        difficulty: 'beginner',
        equipment: 'Dumbbell or Kettlebell',
        targetSets: 3,
        targetReps: 15,
        restSeconds: 60,
        instructions: '1. Hold dumbbell vertically against chest with both hands.\n2. Squat down between knees keeping chest proud.\n3. Drive up through heels.',
      ),

      // ==========================================
      // --- ABS / CORE (8 Premier Exercises) ---
      // ==========================================
      ExerciseModel(
        id: 'plank01',
        name: 'Standard Forearm Plank',
        description: 'Isometric core stability builder engaging transverse abdominis and lower back.',
        muscleGroup: 'Abs/Core',
        difficulty: 'beginner',
        equipment: 'Exercise Mat',
        targetSets: 3,
        targetReps: 1, // 1 rep = 45-60s hold
        restSeconds: 45,
        instructions: '1. Rest on forearms with elbows directly under shoulders.\n2. Keep spine neutral and glutes squeezed.\n3. Hold without letting hips sag.',
      ),
      ExerciseModel(
        id: 'hanging_leg_raise01',
        name: 'Hanging Leg Raises',
        description: 'Advanced lower abdominal builder utilizing pull-up bar support.',
        muscleGroup: 'Abs/Core',
        difficulty: 'intermediate',
        equipment: 'Pull-Up Bar',
        targetSets: 3,
        targetReps: 12,
        restSeconds: 60,
        instructions: '1. Hang from bar with arms straight.\n2. Engage core and raise legs up to horizontal position.\n3. Lower with controlled speed.',
      ),
      ExerciseModel(
        id: 'ab_wheel_rollout01',
        name: 'Ab Wheel Rollout',
        description: 'Brutal anti-extension core strengthener for total abdominal wall power.',
        muscleGroup: 'Abs/Core',
        difficulty: 'advanced',
        equipment: 'Ab Wheel',
        targetSets: 3,
        targetReps: 10,
        restSeconds: 60,
        instructions: '1. Kneel on mat holding ab wheel handles.\n2. Roll wheel forward extending body as far as comfortable.\n3. Pull back using core, not arms.',
      ),
      ExerciseModel(
        id: 'cable_woodchopper01',
        name: 'Cable Woodchoppers',
        description: 'Rotational core powerhouse targeting internal and external obliques.',
        muscleGroup: 'Abs/Core',
        difficulty: 'intermediate',
        equipment: 'Cable Machine',
        targetSets: 3,
        targetReps: 12,
        restSeconds: 45,
        instructions: '1. Set cable high or low, grip handle with both hands.\n2. Rotate torso diagonally across body using obliques.\n3. Return smoothly under control.',
      ),
      ExerciseModel(
        id: 'bicycle_crunches01',
        name: 'Bicycle Crunches',
        description: 'High-activation oblique and rectus abdominis rotational movement.',
        muscleGroup: 'Abs/Core',
        difficulty: 'beginner',
        equipment: 'Exercise Mat',
        targetSets: 3,
        targetReps: 20,
        restSeconds: 45,
        instructions: '1. Lie on back, hands behind head.\n2. Alternate bringing opposite elbow to opposite knee with pedaling motion.\n3. Squeeze obliques on each twist.',
      ),
      ExerciseModel(
        id: 'russian_twist01',
        name: 'Russian Twists',
        description: 'Dynamic rotational core exercise strengthening rotational torque and hip flexors.',
        muscleGroup: 'Abs/Core',
        difficulty: 'beginner',
        equipment: 'Weight Plate or Dumbbell',
        targetSets: 3,
        targetReps: 20,
        restSeconds: 45,
        instructions: '1. Sit on floor with knees bent and feet elevated.\n2. Lean back slightly, rotate torso and weight from side to side.\n3. Keep core braced throughout.',
      ),
      ExerciseModel(
        id: 'cable_crunch01',
        name: 'Kneeling Cable Crunch',
        description: 'Weighted abdominal crunch allowing progressive overload on the six-pack.',
        muscleGroup: 'Abs/Core',
        difficulty: 'intermediate',
        equipment: 'Cable Machine & Rope',
        targetSets: 3,
        targetReps: 15,
        restSeconds: 45,
        instructions: '1. Kneel under high pulley holding rope at temples.\n2. Crunch ribcage down towards pelvis, curving spine.\n3. Squeeze abs for 1 second and slowly return.',
      ),
      ExerciseModel(
        id: 'captain_chair_knee_raise01',
        name: 'Captain’s Chair Knee Raises',
        description: 'Supported lower abdominal knee raise with strict spinal stabilization.',
        muscleGroup: 'Abs/Core',
        difficulty: 'beginner',
        equipment: 'Captain’s Chair Station',
        targetSets: 3,
        targetReps: 15,
        restSeconds: 45,
        instructions: '1. Rest forearms on pads, grip handles.\n2. Pull knees up toward chest with abdominal engagement.\n3. Lower legs slowly without swinging.',
      ),
    ];
  }
}
