import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workout_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../providers/progress_provider.dart';
import '../../widgets/stat_card.dart';
import '../strength/strength_screen.dart';
import '../strength/workout_history_screen.dart';
import '../strength/workout_details_screen.dart';
import '../nutrition/nutrition_screen.dart';
import '../profile/profile_screen.dart';
import '../ai_coach/ai_coach_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      await Future.wait([
        context.read<WorkoutProvider>().loadHistory(user.uid),
        context.read<NutritionProvider>().loadDailyLogs(user.uid),
        context.read<ProgressProvider>().loadProgressData(user.uid),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final workoutProvider = context.watch<WorkoutProvider>();
    final nutritionProvider = context.watch<NutritionProvider>();
    final progressProvider = context.watch<ProgressProvider>();

    final user = authProvider.userProfile;
    final userName = user?.name.isNotEmpty == true ? user!.name : 'Athlete';
    final userWeight = user?.currentWeight ?? progressProvider.latestWeight;

    final recentWorkouts = workoutProvider.workoutHistory.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('OmniFit Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'OmniFit AI Coach',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AiCoachScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'My Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_ai_coach_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AiCoachScreen()),
          );
        },
        backgroundColor: Colors.deepOrange,
        tooltip: 'Ask OmniFit AI Coach',
        child: const Icon(Icons.psychology, color: Colors.white, size: 28),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Text(
                'Welcome back, $userName!',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Goal: ${user?.fitnessGoal.replaceAll('_', ' ').toUpperCase() ?? 'GENERAL FITNESS'}',
                style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),

              // OmniFit AI Coach Hero Card
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AiCoachScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple.shade700,
                        Colors.deepOrange.shade600,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.psychology,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Row(
                              children: [
                                Text(
                                  'OmniFit AI Coach',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 16),
                              ],
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Ask anything on diet, muscle growth, fat loss & custom routines',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white70,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Dynamic Quick Stats Row
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Workouts',
                      value: '${workoutProvider.workoutHistory.length}',
                      icon: Icons.fitness_center,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Weight',
                      value: userWeight != null ? '${userWeight.toStringAsFixed(1)} kg' : '-- kg',
                      icon: Icons.scale,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Calories Today',
                      value: '${nutritionProvider.totalCalories.toStringAsFixed(0)} kcal',
                      icon: Icons.local_fire_department,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Level',
                      value: user?.fitnessLevel.toUpperCase() ?? 'BEGINNER',
                      icon: Icons.bolt,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Training & Activity Shortcuts
              const Text(
                'Quick Access',
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      context,
                      'Nutrition',
                      Icons.restaurant,
                      Colors.green,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NutritionScreen()),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Recent Workouts Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Activity',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (workoutProvider.workoutHistory.isNotEmpty)
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
              const SizedBox(height: 8),

              if (workoutProvider.isLoading && workoutProvider.workoutHistory.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              else if (recentWorkouts.isEmpty)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.directions_run, size: 44, color: Colors.grey[400]),
                          const SizedBox(height: 10),
                          const Text(
                            'No workouts completed yet',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Go to Strength training to record your first workout!',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentWorkouts.length,
                    separatorBuilder: (_, index) => const Divider(height: 0),
                    itemBuilder: (context, index) {
                      final record = recentWorkouts[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepOrange.withValues(alpha: 0.1),
                          child: const Icon(Icons.fitness_center, color: Colors.deepOrange, size: 20),
                        ),
                        title: Text(
                          record.workoutPlanName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${record.durationMinutes} mins • ${record.exerciseRecords.length} exercises • ${record.overallCompletionPercent.toStringAsFixed(0)}% completion',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        trailing: Text(
                          DateFormat('MMM d').format(record.date),
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WorkoutDetailsScreen(record: record),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

              const SizedBox(height: 24),
            ],
          ),
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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
