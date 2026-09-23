import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/stat_card.dart';
import '../strength/strength_screen.dart';
import '../strength/workout_history_screen.dart';
import '../../utils/data_seeder.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FitTrack Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Seed Demo Data',
            onPressed: () async {
              await DataSeeder.seedInitialData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Demo data seeded to Firestore!'),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              // TODO: Navigate to Profile
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Text(
              'Welcome back, ${user?.name ?? 'Athlete'}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Keep pushing towards your goal: ${user?.fitnessGoal.replaceAll('_', ' ') ?? 'General Fitness'}',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Quick Stats Row
            const Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Workouts',
                    value: '12',
                    icon: Icons.fitness_center,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Weight',
                    value: '68.5 kg',
                    icon: Icons.scale,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Calories',
                    value: '1,850',
                    icon: Icons.local_fire_department,
                    color: Colors.orange,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Streak',
                    value: '4 Days',
                    icon: Icons.bolt,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Activity Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Activity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WorkoutHistoryScreen(),
                      ),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),

            // Sample Activity List
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(
                        Icons.fitness_center,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: const Text('Chest Workout'),
                    subtitle: const Text('Completed • 45 mins'),
                    trailing: Text(
                      'Yesterday',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  const Divider(height: 0),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.orange,
                      child: Icon(
                        Icons.directions_run,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: const Text('Morning Run'),
                    subtitle: const Text('3.2 km • 24 mins'),
                    trailing: Text(
                      '2 days ago',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Training Shortcuts
            const Text(
              'Start Training',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    context,
                    'Strength',
                    Icons.fitness_center,
                    Colors.deepOrange,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StrengthScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard(
                    context,
                    'Running',
                    Icons.directions_run,
                    Colors.blue,
                    () {
                      // Navigate to Running tab or screen
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
