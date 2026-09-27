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
      // --- CHEST ---
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

      // --- BACK ---
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

      // --- SHOULDERS ---
      ExerciseModel(
        id: 'overhead_press01',
        name: 'Overhead Shoulder Press',
        description: 'Core vertical pressing movement for anterior deltoids and triceps.',
        muscleGroup: 'Shoulders',
        difficulty: 'intermediate',
        equipment: 'Barbell or Dumbbells',
        targetSets: 4,
        targetReps: 10,
        restSeconds: 75,
        instructions: '1. Stand tall with weights at shoulder height.\n2. Press straight overhead without arching lower back.\n3. Lock out arms, then lower with control.',
      ),
      ExerciseModel(
        id: 'lateral_raise01',
        name: 'Dumbbell Lateral Raise',
        description: 'Crucial isolation movement for building shoulder width and lateral delts.',
        muscleGroup: 'Shoulders',
        difficulty: 'beginner',
        equipment: 'Dumbbells',
        targetSets: 3,
        targetReps: 15,
        restSeconds: 45,
        instructions: '1. Hold dumbbells at sides.\n2. Raise arms out laterally to shoulder height with slight elbow bend.\n3. Lower slowly.',
      ),

      // --- BICEPS ---
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

      // --- TRICEPS ---
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

      // --- LEGS ---
      ExerciseModel(
        id: 'squat01',
        name: 'Bodyweight Squats',
        description: 'Foundational lower body compound movement for quadriceps, hamstrings, and glutes.',
        muscleGroup: 'Legs',
        difficulty: 'beginner',
        equipment: 'Bodyweight',
        targetSets: 3,
        targetReps: 20,
        restSeconds: 60,
        instructions: '1. Stand feet shoulder-width apart.\n2. Push hips back and bend knees until thighs are parallel to floor.\n3. Drive through heels to stand up.',
      ),
      ExerciseModel(
        id: 'barbell_squat01',
        name: 'Barbell Back Squat',
        description: 'The king of lower body exercises for strength and hypertrophy.',
        muscleGroup: 'Legs',
        difficulty: 'intermediate',
        equipment: 'Barbell & Squat Rack',
        targetSets: 4,
        targetReps: 10,
        restSeconds: 90,
        instructions: '1. Rest barbell comfortably across upper traps.\n2. Descend with chest high and knees tracking over toes.\n3. Explosively drive back upward.',
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

      // --- ABS/CORE ---
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
    ];
  }
}
