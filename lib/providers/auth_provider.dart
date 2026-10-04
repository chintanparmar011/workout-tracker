import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  User? _user;
  UserModel? _userProfile;
  bool _isLoading = false;
  bool _isInitializing = true;
  bool _isCheckingProfile = false;
  String? _errorMessage;

  User? get user => _user;
  String get userId => _user?.uid ?? '';
  UserModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  bool get isCheckingProfile => _isCheckingProfile;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;
  bool get isEmailVerified => _authService.isEmailVerified;
  bool get hasCompletedOnboarding => _userProfile != null;

  AuthProvider() {
    _authService.authStateChanges.listen((user) async {
      _user = user;
      _isInitializing = false;
      notifyListeners();

      if (user != null && user.emailVerified) {
        await checkUserProfile();
      } else if (user == null) {
        _userProfile = null;
        notifyListeners();
      }
    });
  }

  void _clearError() {
    _errorMessage = null;
  }

  Future<void> checkUserProfile() async {
    if (_user == null) return;
    _isCheckingProfile = true;
    notifyListeners();

    final result = await _firestoreService.getUserProfile(_user!.uid);

    _userProfile = result.isSuccess ? result.user : null;
    _isCheckingProfile = false;
    notifyListeners();
  }

  Future<bool> updateUserProfile(UserModel updated) async {
    _userProfile = updated;
    notifyListeners();

    final result = await _firestoreService.saveUserProfile(updated);
    if (!result.isSuccess) {
      _errorMessage = result.errorMessage;
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<bool> signUp(String email, String password) async {
    _isLoading = true;
    _clearError();
    notifyListeners();

    final result = await _authService.signUp(email: email, password: password);

    _isLoading = false;
    if (result.isSuccess) {
      _user = result.user;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.errorMessage;
      notifyListeners();
      return false;
    }
  }

  Future<void> checkEmailVerified() async {
    final wasVerified = _authService.isEmailVerified;
    await _authService.reloadUser();
    final updatedUser = FirebaseAuth.instance.currentUser;
    _user = updatedUser;

    if (_user != null && _user!.emailVerified && !wasVerified) {
      await checkUserProfile();
      notifyListeners();
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _clearError();
    notifyListeners();

    final result = await _authService.sendPasswordResetEmail(email);

    _isLoading = false;
    if (!result.isSuccess) {
      _errorMessage = result.errorMessage;
    }
    notifyListeners();
    return result.isSuccess;
  }

  Future<bool> resendVerificationEmail() async {
    final result = await _authService.resendVerificationEmail();
    if (!result.isSuccess) {
      _errorMessage = result.errorMessage;
      notifyListeners();
    }
    return result.isSuccess;
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _clearError();
    notifyListeners();

    final result = await _authService.signIn(email: email, password: password);

    _isLoading = false;
    if (result.isSuccess) {
      _user = result.user;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.errorMessage;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _clearError();
    notifyListeners();

    final result = await _authService.signInWithGoogle();

    _isLoading = false;
    if (result.isSuccess) {
      _user = result.user;
      notifyListeners();
      if (_user != null) {
        await checkUserProfile();
      }
      return true;
    } else {
      _errorMessage = result.errorMessage;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _userProfile = null;
    _errorMessage = null;
    notifyListeners();
  }
}
