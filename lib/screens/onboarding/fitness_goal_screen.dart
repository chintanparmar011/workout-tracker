import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';
import 'fitness_level_screen.dart';

class FitnessGoalScreen extends StatefulWidget {
  const FitnessGoalScreen({super.key});

  @override
  State<FitnessGoalScreen> createState() => _FitnessGoalScreenState();
}

class _FitnessGoalScreenState extends State<FitnessGoalScreen> {
  String? _selectedGoal;

  final _goals = const [
    {'value': 'build_muscle', 'label': 'Build Muscle'},
    {'value': 'gain_weight', 'label': 'Gain Weight'},
    {'value': 'lose_weight', 'label': 'Lose Weight'},
    {'value': 'maintain_weight', 'label': 'Maintain Weight'},
    {'value': 'improve_fitness', 'label': 'Improve General Fitness'},
  ];

  void _next() {
    if (_selectedGoal == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a goal')));
      return;
    }

    context.read<OnboardingProvider>().setFitnessGoal(_selectedGoal!);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FitnessLevelScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fitness Goal')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('What is your primary goal?'),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: _goals.map((goal) {
                  return RadioListTile<String>(
                    title: Text(goal['label']!),
                    value: goal['value']!,
                    groupValue: _selectedGoal,
                    onChanged: (v) => setState(() => _selectedGoal = v),
                  );
                }).toList(),
              ),
            ),
            ElevatedButton(onPressed: _next, child: const Text('Next')),
          ],
        ),
      ),
    );
  }
}
