import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../utils/validators.dart';
import 'fitness_goal_screen.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _gender = 'male';

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;

    context.read<OnboardingProvider>().setPersonalInfo(
      name: _nameController.text.trim(),
      age: int.parse(_ageController.text.trim()),
      gender: _gender,
      height: double.parse(_heightController.text.trim()),
      currentWeight: double.parse(_weightController.text.trim()),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FitnessGoalScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal Information')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => Validators.required(v, fieldName: 'Name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Age'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter your age';
                  final age = int.tryParse(v);
                  if (age == null || age < 10 || age > 100)
                    return 'Enter a valid age';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _gender = v ?? 'male'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _heightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Height (cm)'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter your height';
                  final h = double.tryParse(v);
                  if (h == null || h < 100 || h > 250)
                    return 'Enter a valid height';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Current Weight (kg)',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter your weight';
                  final w = double.tryParse(v);
                  if (w == null || w < 20 || w > 300)
                    return 'Enter a valid weight';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _next, child: const Text('Next')),
            ],
          ),
        ),
      ),
    );
  }
}
