import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;

  final List<String> _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  late List<String> _selectedDays;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().userProfile;
    _nameController = TextEditingController(text: user?.name ?? '');
    _ageController = TextEditingController(text: user?.age?.toString() ?? '');
    _heightController = TextEditingController(
      text: user?.height?.toString() ?? '',
    );
    _selectedDays = List.from(
      user?.availableWorkoutDays ?? ['Monday', 'Wednesday', 'Friday'],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.userProfile;

    if (user != null) {
      final updated = user.copyWith(
        name: _nameController.text.trim(),
        age: int.tryParse(_ageController.text.trim()) ?? user.age,
        height: double.tryParse(_heightController.text.trim()) ?? user.height,
        availableWorkoutDays: _selectedDays,
      );

      final success = await authProvider.updateUserProfile(updated);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Profile updated successfully!'
                  : (authProvider.errorMessage ?? 'Failed to update profile'),
            ),
          ),
        );
        if (success) {
          Navigator.pop(context);
        }
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (val) => val == null || val.trim().isEmpty
                  ? 'Please enter your name'
                  : null,
            ),
            const SizedBox(height: 16),

            // Age
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Age (years)',
                prefixIcon: Icon(Icons.cake_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                if (val != null && val.trim().isNotEmpty) {
                  final age = int.tryParse(val.trim());
                  if (age == null || age < 10 || age > 120) {
                    return 'Please enter a valid age (10-120)';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Height
            TextFormField(
              controller: _heightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Height (cm)',
                prefixIcon: Icon(Icons.height),
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                if (val != null && val.trim().isNotEmpty) {
                  final h = double.tryParse(val.trim());
                  if (h == null || h < 50 || h > 250) {
                    return 'Please enter a valid height in cm (50-250)';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            const Text(
              'Available Workout Days',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select the days you plan to exercise:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _weekDays.map((day) {
                final isSelected = _selectedDays.contains(day);
                return FilterChip(
                  label: Text(day),
                  selected: isSelected,
                  selectedColor: Colors.deepOrange.withValues(alpha: 0.2),
                  checkmarkColor: Colors.deepOrange,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.deepOrange[800] : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDays.add(day);
                      } else {
                        if (_selectedDays.length > 1) {
                          _selectedDays.remove(day);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Select at least one workout day.'),
                            ),
                          );
                        }
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isLoading ? null : _saveProfile,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
