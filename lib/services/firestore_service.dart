import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/exercise_model.dart';
import '../models/workout_model.dart';
import '../models/workout_record_model.dart';

class FirestoreResult {
  final bool isSuccess;
  final String? errorMessage;
  final UserModel? user;

  FirestoreResult.success([this.user]) : isSuccess = true, errorMessage = null;
  FirestoreResult.failure(this.errorMessage) : isSuccess = false, user = null;
}

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _usersRef => _db.collection('users');

  Future<FirestoreResult> saveUserProfile(UserModel user) async {
    try {
      await _usersRef
          .doc(user.uid)
          .set(user.toMap())
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
      if (!doc.exists) {
        return FirestoreResult.success(null); // no profile yet — not an error
      }
      final user = UserModel.fromMap(doc.data() as Map<String, dynamic>);
      return FirestoreResult.success(user);
    } catch (e) {
      return FirestoreResult.failure(_mapError(e));
    }
  }

  // --- Strength Module Methods ---

  Future<List<ExerciseModel>> getExercisesByMuscleGroup(
    String muscleGroup,
  ) async {
    try {
      final snapshot = await _db
          .collection('exercises')
          .where('muscleGroup', isEqualTo: muscleGroup)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => ExerciseModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching exercises: $e');
      return [];
    }
  }

  Future<ExerciseModel?> getExerciseById(String id) async {
    try {
      final doc = await _db.collection('exercises').doc(id).get();
      if (!doc.exists) return null;
      return ExerciseModel.fromMap(doc.id, doc.data()!);
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching exercise by ID: $e');
      return null;
    }
  }

  Future<List<WorkoutPlanModel>> getWorkoutPlans(
    String goal,
    String level,
  ) async {
    try {
      final snapshot = await _db
          .collection('workout_plans')
          .where('goal', isEqualTo: goal)
          .where('fitnessLevel', isEqualTo: level)
          .get();

      return snapshot.docs
          .map((doc) => WorkoutPlanModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching workout plans: $e');
      return [];
    }
  }

  Future<bool> saveWorkoutRecord(
    String userId,
    WorkoutRecordModel record,
  ) async {
    try {
      await _usersRef
          .doc(userId)
          .collection('workout_records')
          .add(record.toMap());
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Error saving workout record: $e');
      return false;
    }
  }

  Future<List<WorkoutRecordModel>> getWorkoutHistory(String userId) async {
    try {
      final snapshot = await _usersRef
          .doc(userId)
          .collection('workout_records')
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => WorkoutRecordModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching workout history: $e');
      return [];
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
    // ignore: avoid_print
    print('Unexpected Firestore error: $e');
    return 'Something went wrong. Please try again.';
  }
}
