import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

class ProgressProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<Map<String, dynamic>> _weightHistory = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get weightHistory => _weightHistory;
  bool get isLoading => _isLoading;

  Future<void> loadWeightHistory(String userId) async {
    _isLoading = true;
    notifyListeners();

    // Mocking for now, will integrate with Firestore in real version
    _weightHistory = [
      {
        'date': DateTime.now().subtract(const Duration(days: 21)),
        'weight': 70.5,
      },
      {
        'date': DateTime.now().subtract(const Duration(days: 14)),
        'weight': 69.8,
      },
      {
        'date': DateTime.now().subtract(const Duration(days: 7)),
        'weight': 69.2,
      },
      {'date': DateTime.now(), 'weight': 68.5},
    ];

    _isLoading = false;
    notifyListeners();
  }
}
