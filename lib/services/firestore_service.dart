import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

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
