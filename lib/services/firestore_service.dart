import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/exercise_model.dart';
import '../models/workout_model.dart';
import '../models/workout_record_model.dart';
import '../models/food_log_model.dart';
import '../models/weight_record_model.dart';
import 'exercise_service.dart';

class FirestoreResult {
  final bool isSuccess;
  final String? errorMessage;
  final UserModel? user;

  FirestoreResult.success([this.user]) : isSuccess = true, errorMessage = null;
  FirestoreResult.failure(this.errorMessage) : isSuccess = false, user = null;
}

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ExerciseService _exerciseService = ExerciseService();

  CollectionReference get _usersRef => _db.collection('users');
  CollectionReference get _plansRef => _db.collection('workout_plans');
  CollectionReference get _exercisesRef => _db.collection('exercises');

  // --- User Profile ---

  Future<FirestoreResult> saveUserProfile(UserModel user) async {
    try {
      await _usersRef
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 15));
      return FirestoreResult.success(user);
    } catch (e) {
      return FirestoreResult.failure(_mapError(e));
    }
  }

  Future<FirestoreResult> getUserProfile(String uid) async {
    try {
      final doc = await _usersRef
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 15));
      if (!doc.exists || doc.data() == null) {
        return FirestoreResult.success(null);
      }
      final user = UserModel.fromMap(doc.data() as Map<String, dynamic>);
      return FirestoreResult.success(user);
    } catch (e) {
      return FirestoreResult.failure(_mapError(e));
    }
  }

  Future<bool> updateUserProfile(
    String uid,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updatedAt'] = DateTime.now().toIso8601String();
      await _usersRef
          .doc(uid)
          .update(updates)
          .timeout(const Duration(seconds: 10));
      return true;
    } catch (_) {
      return false;
    }
  }

  // --- Strength & Workout Plans ---

  Future<List<WorkoutPlanModel>> getWorkoutPlans(
    String goal,
    String level,
  ) async {
    try {
      final snapshot = await _plansRef
          .where('goal', isEqualTo: goal)
          .where('fitnessLevel', isEqualTo: level)
          .get()
          .timeout(const Duration(seconds: 8));

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map(
              (doc) => WorkoutPlanModel.fromMap(
                doc.id,
                doc.data() as Map<String, dynamic>,
              ),
            )
            .toList();
      }
    } catch (_) {
      // Fallback to built-in plans if Firestore query fails or collection is empty
    }

    // Default curated plans matching goal and level
    final defaults = _getDefaultWorkoutPlans(goal, level);
    // Asynchronously try seeding to Firestore so future reads work seamlessly
    _trySeedWorkoutPlans(defaults);
    return defaults;
  }

  // --- Exercises ---

  Future<List<ExerciseModel>> getExercisesByMuscleGroup(
    String muscleGroup,
  ) async {
    try {
      final snapshot = await _exercisesRef
          .where('muscleGroup', isEqualTo: muscleGroup)
          .where('isActive', isEqualTo: true)
          .get()
          .timeout(const Duration(seconds: 6));

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map(
              (doc) => ExerciseModel.fromMap(
                doc.id,
                doc.data() as Map<String, dynamic>,
              ),
            )
            .toList();
      }
    } catch (_) {
      // Fallback
    }

    return _exerciseService.getExercisesByMuscleGroup(muscleGroup);
  }

  Future<ExerciseModel?> getExerciseById(String id) async {
    try {
      final doc = await _exercisesRef
          .doc(id)
          .get()
          .timeout(const Duration(seconds: 5));
      if (doc.exists && doc.data() != null) {
        return ExerciseModel.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }
    } catch (_) {
      // Fallback
    }

    return _exerciseService.getExerciseById(id);
  }

  /// Batch retrieve exercises by IDs avoiding sequential network loops
  Future<List<ExerciseModel>> getExercisesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final List<ExerciseModel> results = [];
    final List<String> missingIds = [];

    // First try local/curated exercise database
    final allCurated = _exerciseService.getAllCuratedExercises();
    for (final id in ids) {
      final match = allCurated.where((e) => e.id == id);
      if (match.isNotEmpty) {
        results.add(match.first);
      } else {
        missingIds.add(id);
      }
    }

    // If any IDs are not in local curated, fetch from Firestore in batch
    if (missingIds.isNotEmpty) {
      try {
        final chunks = <List<String>>[];
        for (var i = 0; i < missingIds.length; i += 10) {
          chunks.add(
            missingIds.sublist(
              i,
              i + 10 > missingIds.length ? missingIds.length : i + 10,
            ),
          );
        }

        for (final chunk in chunks) {
          final snapshot = await _exercisesRef
              .where(FieldPath.documentId, whereIn: chunk)
              .get()
              .timeout(const Duration(seconds: 6));

          for (final doc in snapshot.docs) {
            results.add(
              ExerciseModel.fromMap(doc.id, doc.data() as Map<String, dynamic>),
            );
          }
        }
      } catch (_) {
        // Continue with whatever was found
      }
    }

    return results;
  }

  // --- Workout Records ---

  Future<bool> saveWorkoutRecord(
    String userId,
    WorkoutRecordModel record,
  ) async {
    try {
      await _usersRef
          .doc(userId)
          .collection('workout_records')
          .add(record.toMap())
          .timeout(const Duration(seconds: 12));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<WorkoutRecordModel>> getWorkoutHistory(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _usersRef
          .doc(userId)
          .collection('workout_records')
          .orderBy('date', descending: true)
          .limit(limit)
          .get()
          .timeout(const Duration(seconds: 10));

      return snapshot.docs
          .map((doc) => WorkoutRecordModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // --- Nutrition & Food Logs ---

  Future<bool> addFoodLog(String userId, FoodLogModel log) async {
    if (userId.trim().isEmpty) return false;
    try {
      await _usersRef
          .doc(userId)
          .collection('food_logs')
          .add(log.toMap())
          .timeout(const Duration(seconds: 10));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<FoodLogModel>> getFoodLogsForDate(
    String userId,
    DateTime date,
  ) async {
    if (userId.trim().isEmpty) return [];
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _usersRef
          .doc(userId)
          .collection('food_logs')
          .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('date', isLessThanOrEqualTo: endOfDay.toIso8601String())
          .get()
          .timeout(const Duration(seconds: 8));

      return snapshot.docs
          .map((doc) => FoodLogModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> deleteFoodLog(String userId, String logId) async {
    if (userId.trim().isEmpty || logId.trim().isEmpty) return false;
    try {
      await _usersRef
          .doc(userId)
          .collection('food_logs')
          .doc(logId)
          .delete()
          .timeout(const Duration(seconds: 8));
      return true;
    } catch (_) {
      return false;
    }
  }

  // --- Weight Records ---

  Future<bool> saveWeightRecord(String userId, WeightRecordModel record) async {
    if (userId.trim().isEmpty) return false;
    try {
      await _usersRef
          .doc(userId)
          .collection('weight_records')
          .add(record.toMap())
          .timeout(const Duration(seconds: 10));

      // Safely attempt to update currentWeight on user profile
      try {
        await _usersRef.doc(userId).update({
          'currentWeight': record.weight,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } catch (_) {}

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<WeightRecordModel>> getWeightHistory(String userId) async {
    if (userId.trim().isEmpty) return [];
    try {
      final snapshot = await _usersRef
          .doc(userId)
          .collection('weight_records')
          .orderBy('date', descending: false)
          .get()
          .timeout(const Duration(seconds: 10));

      return snapshot.docs
          .map((doc) => WeightRecordModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // --- Built-in Default Workout Plans ---

  List<WorkoutPlanModel> _getDefaultWorkoutPlans(String goal, String level) {
    return [
      WorkoutPlanModel(
        id: 'chest_press_beginner',
        name: 'Foundational Chest Builder',
        goal: goal,
        fitnessLevel: level,
        muscleGroup: 'Chest',
        description:
            'Focus on chest activation, stability, and pushing strength.',
        exerciseIds: ['pushup01', 'incline_pushup01', 'dumbbell_fly01'],
        estimatedDuration: 30,
      ),
      WorkoutPlanModel(
        id: 'back_thickness_routine',
        name: 'Back & Lat Hypertrophy',
        goal: goal,
        fitnessLevel: level,
        muscleGroup: 'Back',
        description:
            'Complete back session targeting lat width and mid-back thickness.',
        exerciseIds: ['pullup01', 'lat_pulldown01', 'barbell_row01'],
        estimatedDuration: 35,
      ),
      WorkoutPlanModel(
        id: 'shoulder_power_routine',
        name: 'Shoulder Sculpt & Press',
        goal: goal,
        fitnessLevel: level,
        muscleGroup: 'Shoulders',
        description:
            'Develop full, 3D deltoid caps with overhead and lateral movements.',
        exerciseIds: ['overhead_press01', 'lateral_raise01', 'pushup01'],
        estimatedDuration: 25,
      ),
      WorkoutPlanModel(
        id: 'arms_blaster_routine',
        name: 'Arm Blast: Biceps & Triceps',
        goal: goal,
        fitnessLevel: level,
        muscleGroup: 'Biceps',
        description:
            'Antagonistic superset-style arms training for upper arm strength.',
        exerciseIds: [
          'bicep_curl01',
          'tricep_dips01',
          'hammer_curl01',
          'cable_pushdown01',
        ],
        estimatedDuration: 30,
      ),
      WorkoutPlanModel(
        id: 'lower_body_strength',
        name: 'Legs & Lower Body Foundation',
        goal: goal,
        fitnessLevel: level,
        muscleGroup: 'Legs',
        description:
            'Build powerful quads, hamstrings, and glutes with foundational squats and lunges.',
        exerciseIds: ['squat01', 'barbell_squat01', 'lunges01'],
        estimatedDuration: 40,
      ),
      WorkoutPlanModel(
        id: 'core_stability_circuit',
        name: 'Abs & Core Strength Circuit',
        goal: goal,
        fitnessLevel: level,
        muscleGroup: 'Abs/Core',
        description:
            'Isometric holds and dynamic contractions for trunk stability and abdominal endurance.',
        exerciseIds: ['plank01', 'hanging_leg_raise01'],
        estimatedDuration: 20,
      ),
    ];
  }

  void _trySeedWorkoutPlans(List<WorkoutPlanModel> plans) async {
    try {
      for (final plan in plans) {
        await _plansRef.doc(plan.id).set(plan.toMap(), SetOptions(merge: true));
      }
    } catch (_) {
      // Non-critical background seed
    }
  }

  String _mapError(Object e) {
    final msg = e.toString();
    if (msg.contains('permission-denied')) {
      return 'You don\'t have permission to access this data.';
    }
    if (msg.contains('unavailable') || msg.contains('TimeoutException')) {
      return 'No internet connection. Check your network and try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
