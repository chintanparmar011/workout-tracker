import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import 'theme.dart';
import '../screens/auth/verify_email_screen.dart';
import '../screens/onboarding/personal_info_screen.dart';
import '../providers/onboarding_provider.dart';
import '../screens/main_navigation_screen.dart';
import '../providers/workout_provider.dart';
import '../providers/progress_provider.dart';

class FitTrackApp extends StatelessWidget {
  const FitTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
      ],
      child: MaterialApp(
        title: 'FitTrack',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!authProvider.isLoggedIn) {
      return const LoginScreen();
    }

    if (!authProvider.isEmailVerified) {
      return const VerifyEmailScreen();
    }

    if (authProvider.isCheckingProfile) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!authProvider.hasCompletedOnboarding) {
      return const PersonalInfoScreen();
    }

    return const MainNavigationScreen();
  }
}
