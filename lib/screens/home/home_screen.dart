import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workout_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../providers/progress_provider.dart';
import '../../utils/app_images.dart';
import '../strength/strength_screen.dart';
import '../strength/workout_history_screen.dart';
import '../strength/workout_details_screen.dart';
import '../running/running_screen.dart';
import '../nutrition/nutrition_screen.dart';
import '../progress/progress_screen.dart';
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

    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 850;

    return Scaffold(
      backgroundColor: AppTheme.obsidianBlack,
      appBar: AppBar(
        titleSpacing: 20,
        backgroundColor: AppTheme.obsidianBlack,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppTheme.crimsonGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.fitness_center, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'OMNIFIT',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
            if (screenWidth > 380) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.crimsonBerry.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.crimsonBerry, width: 0.8),
                  ),
                  child: Text(
                    user?.fitnessLevel.toUpperCase() ?? 'ATHLETE',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.crimsonBerryLight,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: AppTheme.crimsonBerryLight, size: 22),
            tooltip: 'OmniFit AI Coach',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AiCoachScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white, size: 22),
            tooltip: 'My Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'home_ai_coach_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AiCoachScreen()),
          );
        },
        backgroundColor: AppTheme.crimsonBerry,
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.psychology, size: 22, color: Colors.white),
        label: const Text(
          'AI COACH',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            fontSize: 13,
            color: Colors.white,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 32 : 16,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. HERO ATHLETE BANNER
                    _buildHeroCard(context, userName, user?.fitnessGoal),

                    const SizedBox(height: 24),

                    // 2. LIVE ATHLETE METRICS (Responsive row / grid)
                    _buildMetricsSection(
                      isWide: isWide,
                      workoutCount: workoutProvider.workoutHistory.length,
                      caloriesToday: nutritionProvider.totalCalories,
                      userWeight: userWeight,
                      fitnessLevel: user?.fitnessLevel ?? 'ACTIVE',
                    ),

                    const SizedBox(height: 32),

                    // 3. CORE PLATFORM ARSENAL (Features with athletic photography)
                    _buildSectionTitle(
                      badge: 'ATHLETE ARSENAL',
                      title: 'Smart Training Suites',
                    ),
                    const SizedBox(height: 14),
                    _buildFeatureArsenal(context, isWide),

                    const SizedBox(height: 32),

                    // 4. RECENT ACTIVITY PREVIEW
                    _buildRecentActivitySection(
                      context: context,
                      recentWorkouts: recentWorkouts,
                      isLoading: workoutProvider.isLoading,
                    ),

                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, String userName, String? goal) {
    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      decoration: BoxDecoration(
        color: AppTheme.slateCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.slateBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: SafeAthleticImage(
              imageUrl: AppImages.pushLimitsBanner,
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.9),
                    Colors.black.withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back, $userName',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Goal: ${goal?.replaceAll('_', ' ').toUpperCase() ?? 'GENERAL FITNESS'}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.crimsonBerryLight,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const StrengthScreen()),
                        );
                      },
                      icon: const Icon(Icons.fitness_center, size: 16),
                      label: const Text('Start Workout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.crimsonBerry,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AiCoachScreen()),
                        );
                      },
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: const Text('AI Coach'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSection({
    required bool isWide,
    required int workoutCount,
    required double caloriesToday,
    required double? userWeight,
    required String fitnessLevel,
  }) {
    final cards = [
      _MetricData(
        title: 'WORKOUTS',
        value: '$workoutCount',
        subtitle: 'Sessions completed',
        icon: Icons.fitness_center,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WorkoutHistoryScreen()),
        ),
      ),
      _MetricData(
        title: 'CALORIES',
        value: caloriesToday.toStringAsFixed(0),
        subtitle: 'kcal today',
        icon: Icons.local_fire_department,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NutritionScreen()),
        ),
      ),
      _MetricData(
        title: 'WEIGHT',
        value: userWeight != null ? '${userWeight.toStringAsFixed(1)} kg' : '-- kg',
        subtitle: 'Latest logged',
        icon: Icons.monitor_weight_outlined,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProgressScreen()),
        ),
      ),
      _MetricData(
        title: 'LEVEL',
        value: fitnessLevel.toUpperCase(),
        subtitle: 'Profile status',
        icon: Icons.bolt,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        ),
      ),
    ];

    if (isWide) {
      return Row(
        children: cards.map((c) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _buildMetricTile(c),
            ),
          );
        }).toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        if (availableWidth <= 0) return const SizedBox.shrink();
        final isSingleCol = availableWidth < 280;
        final cardWidth = isSingleCol
            ? availableWidth
            : ((availableWidth - 12) / 2).clamp(1.0, double.infinity);
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards.map((c) {
            return SizedBox(
              width: cardWidth,
              child: _buildMetricTile(c),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMetricTile(_MetricData data) {
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.slateCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.slateBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Icon(data.icon, size: 16, color: AppTheme.crimsonBerryLight),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              data.value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              data.subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle({required String badge, required String title}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.crimsonBerry.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            badge,
            style: const TextStyle(
              color: AppTheme.crimsonBerryLight,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureArsenal(BuildContext context, bool isWide) {
    final features = [
      {
        'title': 'Strength & Hypertrophy',
        'subtitle': 'PPL Splits, custom routine builder, 1RM calculators & rest timer.',
        'image': AppImages.deadlift,
        'tag': 'STRENGTH',
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StrengthScreen()),
        ),
      },
      {
        'title': 'Outdoor GPS Running',
        'subtitle': 'Live distance, pace calculation & OpenStreetMap route renderer.',
        'image': AppImages.runningOutdoor,
        'tag': 'CARDIO',
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RunningScreen()),
        ),
      },
      {
        'title': 'Precision Macro Fueling',
        'subtitle': 'Strict today-only food logging with real-time calorie math.',
        'image': AppImages.healthyNutrition,
        'tag': 'NUTRITION',
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NutritionScreen()),
        ),
      },
      {
        'title': 'OmniFit AI Coach',
        'subtitle': 'Tailored fitness guidance for muscle growth, cutting & routines.',
        'image': AppImages.aiCoach,
        'tag': 'AI TRAINER',
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AiCoachScreen()),
        ),
      },
    ];

    if (isWide) {
      return Row(
        children: features.map((f) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _buildArsenalCard(f),
            ),
          );
        }).toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        if (availableWidth <= 0) return const SizedBox.shrink();
        final isSingleCol = availableWidth < 280;
        final cardWidth = isSingleCol
            ? availableWidth
            : ((availableWidth - 12) / 2).clamp(1.0, double.infinity);
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: features.map((f) {
            return SizedBox(
              width: cardWidth,
              child: _buildArsenalCard(f),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildArsenalCard(Map<String, dynamic> f) {
    return InkWell(
      onTap: f['action'] as VoidCallback,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppTheme.slateCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.slateBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            SafeAthleticImage(
              imageUrl: f['image'] as String,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.crimsonBerry,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      f['tag'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    f['title'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    f['subtitle'] as String,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection({
    required BuildContext context,
    required List<dynamic> recentWorkouts,
    required bool isLoading,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(
              badge: 'SESSION LOG',
              title: 'Recent Activity',
            ),
            if (recentWorkouts.isNotEmpty)
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
        const SizedBox(height: 12),
        if (isLoading && recentWorkouts.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (recentWorkouts.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.slateCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.slateBorder),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.directions_run, size: 40, color: AppTheme.textMuted),
                  const SizedBox(height: 10),
                  const Text(
                    'No workouts completed yet',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Go to Strength training to record your first workout!',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: recentWorkouts.map((record) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppTheme.slateCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.slateBorder),
                ),
                child: Material(
                  color: AppTheme.slateCard,
                  borderRadius: BorderRadius.circular(18),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.crimsonBerry.withValues(alpha: 0.15),
                      child: const Icon(Icons.fitness_center, color: AppTheme.crimsonBerryLight, size: 20),
                    ),
                    title: Text(
                      record.workoutPlanName,
                      style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    subtitle: Text(
                      '${record.durationMinutes} mins • ${record.exerciseRecords.length} exercises • ${record.overallCompletionPercent.toStringAsFixed(0)}% done',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    trailing: Text(
                      DateFormat('MMM d').format(record.date),
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WorkoutDetailsScreen(record: record),
                        ),
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _MetricData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  _MetricData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}
