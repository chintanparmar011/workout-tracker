import 'package:firebase_auth/firebase_auth.dart';

class AuthResult {
  final User? user;
  final String? errorMessage;

  AuthResult.success(this.user) : errorMessage = null;
  AuthResult.failure(this.errorMessage) : user = null;

  bool get isSuccess => errorMessage == null;
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 15));

      // Send verification email immediately after signup
      await credential.user?.sendEmailVerification();

      return AuthResult.success(credential.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e));
    } catch (e) {
      return AuthResult.failure(_mapGenericError(e));
    }
  }

  Future<AuthResult> resendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
      return AuthResult.success(_auth.currentUser);
    } catch (e) {
      return AuthResult.failure(
        'Could not send verification email. Try again.',
      );
    }
  }

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 15));
      return AuthResult.success(credential.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e));
    } catch (e) {
      return AuthResult.failure(_mapGenericError(e));
    }
  }

  Future<AuthResult> signOut() async {
    try {
      await _auth.signOut();
      return AuthResult.success(null);
    } catch (e) {
      return AuthResult.failure('Failed to sign out. Please try again.');
    }
  }

  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _auth
          .sendPasswordResetEmail(email: email)
          .timeout(const Duration(seconds: 15));
      return AuthResult.success(null);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e));
    } catch (e) {
      return AuthResult.failure(_mapGenericError(e));
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'network-request-failed':
        return 'No internet connection. Check your network and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        // Log unexpected auth error codes for debugging, but don't show raw
        // Firebase text to the user.
        // ignore: avoid_print
        print('Unhandled FirebaseAuthException code: ${e.code} — ${e.message}');
        return 'Something went wrong. Please try again.';
    }
  }

  String _mapGenericError(Object e) {
    if (e.toString().contains('TimeoutException')) {
      return 'Request timed out. Check your internet connection.';
    }
    // ignore: avoid_print
    print('Unexpected auth error: $e');
    return 'Unexpected error. Please try again.';
  }
}
