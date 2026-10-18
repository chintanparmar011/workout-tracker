import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittracker/app/theme.dart';
import 'package:fittracker/models/food_model.dart';
import 'package:fittracker/screens/landing/landing_screen.dart';
import 'package:fittracker/widgets/google_sign_in_button.dart';
import 'package:fittracker/models/workout_record_model.dart';
import 'package:fittracker/screens/strength/workout_details_screen.dart';
import 'package:fittracker/screens/strength/create_custom_plan_screen.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  group('Crimson Berry & Obsidian Design Suite Tests', () {
    test('AppTheme Crimson Berry & Obsidian Palette constants are properly defined', () {
      expect(AppTheme.crimsonBerry, const Color(0xFFBA0C48));
      expect(AppTheme.obsidianBlack, const Color(0xFF0D0E13));
      expect(AppTheme.slateCard, const Color(0xFF161822));

      expect(AppTheme.darkTheme.scaffoldBackgroundColor, AppTheme.obsidianBlack);
      expect(AppTheme.lightTheme.scaffoldBackgroundColor, AppTheme.obsidianBlack);
    });

    test('FoodModel.displayName formats USDA and parenthesized strings cleanly without broken braces', () {
      // 1. Regular USDA description with commas
      final food1 = FoodModel(
        id: '1',
        name: 'CHICKEN, BREAST, COOKED, SKINLESS',
        servingSize: '100g',
        calories: 165,
        protein: 31,
        carbs: 0,
        fat: 3.6,
      );
      expect(food1.displayName, 'Chicken Breast (Cooked, Skinless)');

      // 2. Food with already balanced parentheses
      final food2 = FoodModel(
        id: '2',
        name: 'Chicken Breast (Cooked, Skinless)',
        servingSize: '100g',
        calories: 165,
        protein: 31,
        carbs: 0,
        fat: 3.6,
      );
      expect(food2.displayName, 'Chicken Breast (Cooked, Skinless)');

      // 3. Simple two-token USDA food
      final food3 = FoodModel(
        id: '3',
        name: 'OATS, ROLLED',
        servingSize: '100g',
        calories: 389,
        protein: 16,
        carbs: 66,
        fat: 7,
      );
      expect(food3.displayName, 'Oats (Rolled)');

      // 4. Single token
      final food4 = FoodModel(
        id: '4',
        name: 'BANANA',
        servingSize: '100g',
        calories: 89,
        protein: 1,
        carbs: 23,
        fat: 0.3,
      );
      expect(food4.displayName, 'Banana');
    });

    testWidgets('GoogleSignInButton renders text and triggers callback', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: GoogleSignInButton(
              text: 'Continue with Google',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Continue with Google'), findsOneWidget);

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      expect(pressed, isTrue);
    });

    testWidgets('LandingScreen renders hero, features, FAQs and Get Started button', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const LandingScreen(),
        ),
      );

      expect(find.text('OMNIFIT'), findsWidgets);
      expect(find.text('Push Limits.\nUnlock Your Power.'), findsOneWidget);
      expect(find.text('Smart Training For Real Results'), findsOneWidget);
      expect(find.text('Get Started'), findsWidgets);
      expect(find.text('Log In'), findsWidgets);
    });

    testWidgets('LandingScreen resizes seamlessly between desktop (1200px) and mobile (360px) without overflow or negative constraints', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const LandingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Resize to mobile
      tester.view.physicalSize = const Size(360, 800);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Resize to very narrow mobile (320px)
      tester.view.physicalSize = const Size(320, 600);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Resize back to desktop
      tester.view.physicalSize = const Size(1440, 900);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    test('AppTheme darkTheme includes valid ChipThemeData with Crimson Berry active palette', () {
      final chipTheme = AppTheme.darkTheme.chipTheme;
      expect(chipTheme.selectedColor, AppTheme.crimsonBerry);
      expect(chipTheme.backgroundColor, AppTheme.slateCard);
    });

    testWidgets('WorkoutDetailsScreen resizes down to 320px without overflow', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final dummyRecord = WorkoutRecordModel(
        id: 'test_rec_1',
        workoutPlanId: 'plan_1',
        workoutPlanName: 'Push Hypertrophy Pro',
        date: DateTime.now(),
        durationMinutes: 55,
        exerciseRecords: [
          ExerciseRecord(
            exerciseId: 'bench_press',
            exerciseName: 'Barbell Bench Press',
            targetSets: 4,
            targetReps: 10,
            actualSets: [
              ActualSet(reps: 10, weight: 80),
              ActualSet(reps: 10, weight: 80),
              ActualSet(reps: 8, weight: 85),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: WorkoutDetailsScreen(record: dummyRecord),
        ),
      );
      await tester.pumpAndSettle();

      // Resize down to narrow mobile
      tester.view.physicalSize = const Size(320, 600);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Resize to standard mobile
      tester.view.physicalSize = const Size(375, 812);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('CreateCustomPlanScreen resizes down to 320px mobile view without dropdown overflow', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const CreateCustomPlanScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create Custom Workout Plan'), findsOneWidget);
      expect(find.text('Intermediate'), findsOneWidget);

      // Resize down to standard mobile (375px)
      tester.view.physicalSize = const Size(375, 812);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Resize down to narrow mobile (320px) - where the 12px overflow previously happened!
      tester.view.physicalSize = const Size(320, 600);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Resize back to desktop
      tester.view.physicalSize = const Size(1440, 900);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();
  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => _kTransparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_kTransparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

final Uint8List _kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
]);
