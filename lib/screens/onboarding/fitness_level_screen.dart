import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../providers/onboarding_provider.dart';
import '../../providers/auth_provider.dart';

class FitnessLevelScreen extends StatefulWidget {
  const FitnessLevelScreen({super.key});

  @override
  State<FitnessLevelScreen> createState() => _FitnessLevelScreenState();
}

class _FitnessLevelScreenState extends State<FitnessLevelScreen> {
  String _level = 'beginner';
  final Set<String> _selectedMuscles = {};
  final Set<String> _selectedDays = {};

  final _muscleGroups = const [
    'chest',
    'back',
    'shoulders',
    'biceps',
    'triceps',
    'legs',
    'abs_core',
  ];
  final _days = const [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  Future<void> _finish() async {
    if (_selectedMuscles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one target muscle group'),
        ),
      );
      return;
    }
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one available day')),
      );
      return;
    }

    final onboardingProvider = context.read<OnboardingProvider>();
    onboardingProvider.setFitnessLevel(
      level: _level,
      muscles: _selectedMuscles.toList(),
      days: _selectedDays.toList(),
    );

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return; // shouldn't happen — safety check

    final success = await onboardingProvider.submitOnboarding(
      currentUser.uid,
      currentUser.email ?? '',
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            onboardingProvider.errorMessage ?? 'Failed to save profile',
          ),
        ),
      );
      return;
    }

    // Trigger profile reload in AuthProvider so _AuthGate switches to Home
    if (mounted) {
      await context.read<AuthProvider>().checkUserProfile();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingProvider = context.watch<OnboardingProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Fitness Level')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            const Text('Fitness Level'),
            RadioListTile(
              title: const Text('Beginner'),
              value: 'beginner',
              groupValue: _level,
              onChanged: (v) => setState(() => _level = v ?? 'beginner'),
            ),
            RadioListTile(
              title: const Text('Intermediate'),
              value: 'intermediate',
              groupValue: _level,
              onChanged: (v) => setState(() => _level = v ?? 'beginner'),
            ),
            const SizedBox(height: 16),
            const Text('Target Muscle Groups'),
            Wrap(
              spacing: 8,
              children: _muscleGroups.map((muscle) {
                final selected = _selectedMuscles.contains(muscle);
                return FilterChip(
                  label: Text(muscle.replaceAll('_', ' ')),
                  selected: selected,
                  onSelected: (sel) => setState(() {
                    sel
                        ? _selectedMuscles.add(muscle)
                        : _selectedMuscles.remove(muscle);
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Available Workout Days'),
            Wrap(
              spacing: 8,
              children: _days.map((day) {
                final selected = _selectedDays.contains(day);
                return FilterChip(
                  label: Text(day.substring(0, 3)),
                  selected: selected,
                  onSelected: (sel) => setState(() {
                    sel ? _selectedDays.add(day) : _selectedDays.remove(day);
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onboardingProvider.isSaving ? null : _finish,
              child: onboardingProvider.isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Finish'),
            ),
          ],
        ),
      ),
    );
  }
}
