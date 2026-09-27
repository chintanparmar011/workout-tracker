import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _goals = const [
    {'value': 'build_muscle', 'label': 'Build Muscle'},
    {'value': 'gain_weight', 'label': 'Gain Weight'},
    {'value': 'lose_weight', 'label': 'Lose Weight'},
    {'value': 'maintain_weight', 'label': 'Maintain Weight'},
    {'value': 'improve_fitness', 'label': 'Improve General Fitness'},
  ];

  final _levels = const [
    {'value': 'beginner', 'label': 'Beginner'},
    {'value': 'intermediate', 'label': 'Intermediate'},
    {'value': 'advanced', 'label': 'Advanced'},
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userProfile;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log Out',
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // User Avatar & Name Card
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.deepOrange.withValues(alpha: 0.15),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'A',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.name.isNotEmpty ? user.name : 'Athlete',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Physical Attributes Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAttrTile('Age', '${user.age ?? "-"}'),
                  _buildDivider(),
                  _buildAttrTile('Gender', user.gender?.toUpperCase() ?? '-'),
                  _buildDivider(),
                  _buildAttrTile('Height', user.height != null ? '${user.height!.toStringAsFixed(0)} cm' : '-'),
                  _buildDivider(),
                  _buildAttrTile('Weight', user.currentWeight != null ? '${user.currentWeight!.toStringAsFixed(1)} kg' : '-'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Goal & Level Settings
          const Text('Training Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.flag_outlined, color: Colors.deepOrange),
                  title: const Text('Fitness Goal'),
                  subtitle: Text(_goals.firstWhere((g) => g['value'] == user.fitnessGoal, orElse: () => {'label': user.fitnessGoal})['label']!),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _editGoalDialog(context, user),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.bar_chart, color: Colors.deepOrange),
                  title: const Text('Fitness Level'),
                  subtitle: Text(user.fitnessLevel.toUpperCase()),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _editLevelDialog(context, user),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.deepOrange),
                  title: const Text('Available Days'),
                  subtitle: Text(user.availableWorkoutDays.isNotEmpty
                      ? user.availableWorkoutDays.map((d) => d.substring(0, 3).toUpperCase()).join(', ')
                      : 'Not configured'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Log Out'),
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 30, width: 1, color: Colors.grey[300]);
  }

  Widget _buildAttrTile(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  void _editGoalDialog(BuildContext context, UserModel user) {
    String selected = user.fitnessGoal;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setStateDialog) => AlertDialog(
          title: const Text('Select Fitness Goal'),
          content: RadioGroup<String>(
            groupValue: selected,
            onChanged: (val) => setStateDialog(() => selected = val!),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _goals.map((g) {
                return RadioListTile<String>(
                  title: Text(g['label']!),
                  value: g['value']!,
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final updated = user.copyWith(fitnessGoal: selected);
                await context.read<AuthProvider>().updateUserProfile(updated);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _editLevelDialog(BuildContext context, UserModel user) {
    String selected = user.fitnessLevel;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setStateDialog) => AlertDialog(
          title: const Text('Select Fitness Level'),
          content: RadioGroup<String>(
            groupValue: selected,
            onChanged: (val) => setStateDialog(() => selected = val!),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _levels.map((lvl) {
                return RadioListTile<String>(
                  title: Text(lvl['label']!),
                  value: lvl['value']!,
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final updated = user.copyWith(fitnessLevel: selected);
                await context.read<AuthProvider>().updateUserProfile(updated);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of FitTrack?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Close ProfileScreen if opened
              context.read<AuthProvider>().signOut();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
