import 'package:flutter/material.dart';
import '../models/ai_message_model.dart';
import '../models/user_model.dart';
import '../services/ai_fitness_service.dart';
import '../services/firestore_service.dart';

class AiCoachProvider extends ChangeNotifier {
  final AiFitnessService _aiService;
  final FirestoreService _firestoreService;

  final List<AiMessageModel> _messages = [];
  bool _isLoading = false;
  String? _customApiKey;
  String? _currentUserId;

  List<AiMessageModel> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get customApiKey => _customApiKey;

  final List<String> suggestionChips = [
    '💪 How to build muscle fast?',
    '🦅 Best back muscle growth routine',
    '🦵 Complete legs training workout',
    '🥗 High-protein diet for bulking',
    '🔥 How to lose fat without losing muscle?',
    '🥛 Do I need creatine and whey protein?',
    '🏋️ Best workout split for beginners',
  ];

  AiCoachProvider({
    AiFitnessService? aiService,
    FirestoreService? firestoreService,
  })  : _aiService = aiService ?? AiFitnessService(),
        _firestoreService = firestoreService ?? FirestoreService() {
    _initWelcomeMessage();
  }

  void _initWelcomeMessage() {
    _messages.add(
      AiMessageModel(
        id: 'welcome_1',
        content: '''
### 👋 Welcome to OmniFit AI Coach!

I am your personal AI fitness and sports nutrition specialist powered by Google Gemini. I am strictly dedicated to helping you achieve your physical goals, including:

- 🥗 **Diet & Nutrition**: Customized meal ideas, macros, calorie targets
- 💪 **Muscle Growth & Hypertrophy**: Progressive overload, optimal rep ranges, training splits
- 🦅 **Back & Legs Specialization**: Complete routines and form cues
- ⚖️ **Weight Management**: Sustainable fat loss protocols or clean bulking strategies
- 🏋️ **Workout Routines**: Form cues, exercise selection, and recovery

Tap one of the quick suggestions below or type any fitness question!
''',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> loadChatHistory(String userId) async {
    _currentUserId = userId;
    if (userId.trim().isEmpty || userId == 'guest') return;

    try {
      final history = await _firestoreService.getAiChatHistory(userId, limit: 50);
      if (history.isNotEmpty) {
        _messages.clear();
        _messages.addAll(history);
        notifyListeners();
      }
    } catch (_) {
      // Keep existing memory state on error
    }
  }

  void setCustomApiKey(String key) {
    _customApiKey = key.trim().isEmpty ? null : key.trim();
    notifyListeners();
  }

  Future<void> sendMessage(String text, {UserModel? userProfile, String? userId}) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty || _isLoading) return;

    final effectiveUserId = userId ?? userProfile?.uid ?? _currentUserId ?? '';

    final userMessage = AiMessageModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      content: cleanText,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _messages.add(userMessage);
    _isLoading = true;
    notifyListeners();

    // Persist user message to Firestore
    if (effectiveUserId.isNotEmpty) {
      _firestoreService.saveAiChatMessage(effectiveUserId, userMessage);
    }

    try {
      final aiResponse = await _aiService.getFitnessAdvice(
        userQuery: cleanText,
        userProfile: userProfile,
        conversationHistory: _messages,
        customApiKey: _customApiKey,
      );

      _messages.add(aiResponse);

      // Persist AI response to Firestore
      if (effectiveUserId.isNotEmpty) {
        _firestoreService.saveAiChatMessage(effectiveUserId, aiResponse);
      }
    } catch (_) {
      final errorMsg = AiMessageModel(
        id: 'err_${DateTime.now().millisecondsSinceEpoch}',
        content:
            '⚠️ Unable to retrieve advice right now. Please check your network connection and try again.',
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      );
      _messages.add(errorMsg);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearChat([String? userId]) async {
    final uid = userId ?? _currentUserId;
    if (uid != null && uid.isNotEmpty) {
      await _firestoreService.clearAiChatHistory(uid);
    }
    _messages.clear();
    _initWelcomeMessage();
    notifyListeners();
  }
}
