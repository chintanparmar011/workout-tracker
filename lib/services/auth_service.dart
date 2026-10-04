import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthResult {
  final User? user;
  final String? errorMessage;

  AuthResult.success(this.user) : errorMessage = null;
  AuthResult.failure(this.errorMessage) : user = null;

  bool get isSuccess => errorMessage == null;
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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

  Future<AuthResult> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Native Firebase Web popup flow - avoids client_id assertion error on web
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        // Force Google Account Chooser so user can select another Gmail or switch accounts
        googleProvider.setCustomParameters({
          'prompt': 'select_account',
        });
        final userCredential = await _auth
            .signInWithPopup(googleProvider)
            .timeout(const Duration(seconds: 45));

        return AuthResult.success(userCredential.user);
      } else {
        // Native Android / iOS Google Sign In flow
        // Disconnecting / signing out prior to prompt forces account chooser dialog
        try {
          await _googleSignIn.signOut();
        } catch (_) {}
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          return AuthResult.failure('Google Sign-In was cancelled.');
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await _auth
            .signInWithCredential(credential)
            .timeout(const Duration(seconds: 25));

        return AuthResult.success(userCredential.user);
      }
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e));
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('sign_in_canceled') ||
          errStr.contains('popup_closed') ||
          errStr.contains('popup-closed') ||
          errStr.contains('canceled') ||
          errStr.contains('cancelled') ||
          errStr.contains('closed_by_user')) {
        return AuthResult.failure('Google Sign-In was cancelled.');
      }
      return AuthResult.failure(_mapGenericError(e));
    }
  }

  Future<AuthResult> signOut() async {
    try {
      await _auth.signOut();
      if (!kIsWeb) {
        try {
          await _googleSignIn.signOut();
        } catch (_) {}
      }
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
      case 'popup-closed-by-user':
        return 'Google Sign-In was cancelled.';
      case 'cancelled-popup-request':
        return 'Previous sign-in request was cancelled.';
      case 'popup-blocked':
        return 'Sign-in popup was blocked by browser. Please allow popups for this site.';
      case 'operation-not-allowed':
        return 'Google Sign-In is not enabled in Firebase Console. Please enable it under Authentication > Sign-in method.';
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
        return 'Something went wrong (${e.code}). Please try again.';
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
