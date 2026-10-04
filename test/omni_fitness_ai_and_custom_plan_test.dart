import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittracker/services/ai_fitness_service.dart';
import 'package:fittracker/models/workout_model.dart';
import 'package:fittracker/providers/ai_coach_provider.dart';
import 'package:fittracker/providers/nutrition_provider.dart';
import 'package:fittracker/utils/validators.dart';

void main() {
  group('AiFitnessService Offline Engine & Topic Specificity Tests', () {
    final aiService = AiFitnessService();
    // Using customApiKey: 'your_api_key' forces deterministic built-in offline engine test
    const offlineTestKey = 'your_api_key';

    test('Answers muscle growth query with fitness hypertrophy advice', () async {
      final response = await aiService.getFitnessAdvice(
        userQuery: 'How do I build muscle and increase hypertrophy?',
        customApiKey: offlineTestKey,
      );
      expect(response.content, contains('Muscle Growth'));
      expect(response.content, contains('Progressive Overload'));
      expect(response.content, contains('Protein Target'));
    });

    test('Answers fat loss query with caloric deficit and satiety advice', () async {
      final response = await aiService.getFitnessAdvice(
        userQuery: 'How can I lose body fat sustainably?',
        customApiKey: offlineTestKey,
      );
      expect(response.content.toLowerCase(), contains('fat loss'));
      expect(response.content, contains('Caloric Deficit'));
    });

    test('Answers diet query with balanced meals and macros', () async {
      final response = await aiService.getFitnessAdvice(
        userQuery: 'What is a good high-protein diet meal plan?',
        customApiKey: offlineTestKey,
      );
      expect(response.content, contains('Nutrition & Diet Plan'));
      expect(response.content, contains('Breakfast'));
    });

    test('Answers legs training with dedicated quad, squat and hamstring routines', () async {
      final response = await aiService.getFitnessAdvice(
        userQuery: 'Give me a routine for legs training',
        customApiKey: offlineTestKey,
      );
      expect(response.content, contains('Leg Training'));
      expect(response.content, contains('Squat'));
      expect(response.content, contains('Hamstring'));
    });

    test('Answers back muscle growth with dedicated lat, row and pull-up routines', () async {
      final response = await aiService.getFitnessAdvice(
        userQuery: 'How to optimize back muscle growth?',
        customApiKey: offlineTestKey,
      );
      expect(response.content, contains('Back Growth'));
      expect(response.content, contains('Barbell Row'));
      expect(response.content, contains('Lat Pulldown'));
    });

    test('Legs training and back muscle growth return completely distinct, specialized advice', () async {
      final legsResponse = await aiService.getFitnessAdvice(
        userQuery: 'legs training',
        customApiKey: offlineTestKey,
      );
      final backResponse = await aiService.getFitnessAdvice(
        userQuery: 'back muscle growth',
        customApiKey: offlineTestKey,
      );

      expect(legsResponse.content, isNot(equals(backResponse.content)));
      expect(legsResponse.content.toLowerCase(), contains('leg'));
      expect(backResponse.content.toLowerCase(), contains('back'));
    });

    test('Strictly blocks non-fitness query with OmniFit guardrail message', () async {
      final response = await aiService.getFitnessAdvice(
        userQuery: 'Can you write python code for a movie review website?',
        customApiKey: offlineTestKey,
      );
      expect(
        response.content,
        contains('I am **OmniFit AI Coach**, specialized exclusively in fitness'),
      );
    });
  });

  group('WorkoutPlanModel Custom Routine Tests', () {
    test('Correctly serializes and deserializes custom workout plan', () {
      final plan = WorkoutPlanModel(
        id: 'custom_12345',
        name: 'Upper Body Blast',
        goal: 'build_muscle',
        fitnessLevel: 'intermediate',
        muscleGroup: 'Full Body',
        description: 'Heavy chest and lat routine',
        exerciseIds: ['bench_press01', 'pullup01', 'bicep_curl01'],
        estimatedDuration: 50,
      );

      final map = plan.toMap();
      expect(map['name'], 'Upper Body Blast');
      expect(map['exerciseIds'].length, 3);
      expect(map['estimatedDuration'], 50);

      final deserialized = WorkoutPlanModel.fromMap(plan.id, map);
      expect(deserialized.id, 'custom_12345');
      expect(deserialized.name, 'Upper Body Blast');
      expect(deserialized.exerciseIds, contains('bench_press01'));
      expect(deserialized.estimatedDuration, 50);
    });
  });

  group('AiCoachProvider State Tests', () {
    test('Initializes with welcome message and suggestion chips', () {
      final provider = AiCoachProvider();
      expect(provider.messages.isNotEmpty, isTrue);
      expect(provider.messages.first.content, contains('Welcome to OmniFit AI Coach'));
      expect(provider.suggestionChips.length, greaterThanOrEqualTo(5));
      expect(provider.isLoading, isFalse);
    });

    test('Clearing chat resets to initial welcome message', () {
      final provider = AiCoachProvider();
      provider.clearChat();
      expect(provider.messages.length, 1);
      expect(provider.messages.first.content, contains('OmniFit AI Coach'));
    });
  });

  group('Nutrition Date Bounds & Selection Tests', () {
    test('Clamps future date navigation to today (no future days allowed)', () async {
      final provider = NutritionProvider();
      final today = DateUtils.dateOnly(DateTime.now());
      final futureDate = today.add(const Duration(days: 4));
      final accountCreated = today.subtract(const Duration(days: 10));

      await provider.changeDate(
        '',
        futureDate,
        minDate: accountCreated,
        maxDate: today,
      );

      expect(provider.selectedDate, equals(today));
    });

    test('Clamps prior date navigation to account creation date (no pre-account days)', () async {
      final provider = NutritionProvider();
      final today = DateUtils.dateOnly(DateTime.now());
      final accountCreated = today.subtract(const Duration(days: 7));
      final pastDate = accountCreated.subtract(const Duration(days: 10));

      await provider.changeDate(
        '',
        pastDate,
        minDate: accountCreated,
        maxDate: today,
      );

      expect(provider.selectedDate, equals(accountCreated));
    });

    test('Allows navigation to valid dates between account creation and today', () async {
      final provider = NutritionProvider();
      final today = DateUtils.dateOnly(DateTime.now());
      final accountCreated = today.subtract(const Duration(days: 7));
      final validMidDate = today.subtract(const Duration(days: 3));

      await provider.changeDate(
        '',
        validMidDate,
        minDate: accountCreated,
        maxDate: today,
      );

      expect(provider.selectedDate, equals(validMidDate));
    });
  });

  group('Password Constraints & Validation Tests', () {
    test('Rejects passwords shorter than 8 characters for new registration', () {
      final err = Validators.strongPassword('Abc1@');
      expect(err, contains('at least 8 characters long'));
    });

    test('Rejects passwords missing uppercase letters', () {
      final err = Validators.strongPassword('omnifit@2026');
      expect(err, contains('uppercase letter'));
    });

    test('Rejects passwords missing lowercase letters', () {
      final err = Validators.strongPassword('OMNIFIT@2026');
      expect(err, contains('lowercase letter'));
    });

    test('Rejects passwords missing numbers', () {
      final err = Validators.strongPassword('OmniFit@Pass');
      expect(err, contains('number'));
    });

    test('Rejects passwords missing special characters', () {
      final err = Validators.strongPassword('OmniFit2026');
      expect(err, contains('special character'));
    });

    test('Accepts valid strong password meeting all constraints', () {
      final err = Validators.strongPassword('OmniFit@2026');
      expect(err, isNull);
    });

    test('Allows existing users with normal/legacy passwords to log in', () {
      // Normal simple passwords allowed for login
      expect(Validators.loginPassword('password123'), isNull);
      expect(Validators.loginPassword('secret'), isNull);
      expect(Validators.loginPassword('123456'), isNull);

      // Rejects only empty password
      expect(Validators.loginPassword(''), equals('Enter your password'));
      expect(Validators.loginPassword(null), equals('Enter your password'));
    });
  });
}
