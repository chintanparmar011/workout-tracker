import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  bool _isInitializing = true; // NEW
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing; // NEW
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;
  bool get isEmailVerified => _authService.isEmailVerified;

  final FirestoreService _firestoreService = FirestoreService();
  UserModel? _userProfile;
  bool _isCheckingProfile = false;

  UserModel? get userProfile => _userProfile;
  bool get isCheckingProfile => _isCheckingProfile;
  bool get hasCompletedOnboarding => _userProfile != null;

  Future<void> checkUserProfile() async {
    if (_user == null) return;
    _isCheckingProfile = true;
    notifyListeners();

    final result = await _firestoreService.getUserProfile(_user!.uid);

    _userProfile = result.isSuccess ? result.user : null;
    _isCheckingProfile = false;
    notifyListeners();
  }

  AuthProvider() {
    _authService.authStateChanges.listen((user) async {
      _user = user;
      _isInitializing = false;
      notifyListeners();

      if (user != null && user.emailVerified) {
        await checkUserProfile();
      }
    });
  }

  void _clearError() {
    _errorMessage = null;
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
    await _authService.reloadUser();
    notifyListeners();
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

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }
}
