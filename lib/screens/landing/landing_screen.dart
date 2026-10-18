import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../utils/app_images.dart';
import '../../widgets/app_brand.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;
    final isTablet = screenWidth > 600 && screenWidth <= 900;

    return Scaffold(
      backgroundColor: AppTheme.deepPlum,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            _buildTopBar(context, isWide),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 40 : 20,
                        vertical: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. HERO SECTION (Figma Mobile UI Kit inspired)
                          _buildHeroSection(context, isWide, isTablet),

                          const SizedBox(height: 36),

                          // 2. STATS BANNER
                          _buildQuickMetricsBanner(isWide),

                          const SizedBox(height: 48),

                          // 3. FEATURE PILLARS WITH ATHLETIC IMAGERY
                          _buildSectionHeader(
                            badge: 'CORE PILLARS',
                            title: 'Smart Training For Real Results',
                            subtitle:
                                'Everything you need to break plateaus, log runs, track macros, and master your fitness.',
                          ),
                          const SizedBox(height: 24),
                          _buildFeatureGrid(context, isWide, isTablet),

                          const SizedBox(height: 56),

                          // 4. QUESTIONS & FAQ ACCORDION (Showcased Before Login)
                          _buildSectionHeader(
                            badge: 'FREQUENTLY ASKED QUESTIONS',
                            title: 'Everything You Need To Know',
                            subtitle:
                                'Clear answers on features, workouts, food logging, and zero-subscription access.',
                          ),
                          const SizedBox(height: 20),
                          _buildFaqList(),

                          const SizedBox(height: 56),

                          // 5. CALL TO ACTION BANNER
                          _buildCtaCard(context),

                          const SizedBox(height: 40),

                          // 6. BRAND FOOTER
                          _buildFooter(),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isWide
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.slateCard,
                border: const Border(
                  top: BorderSide(color: AppTheme.slateBorder, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        side: const BorderSide(color: AppTheme.slateBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text('Log In'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.crimsonBerry,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Get Started',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isWide) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 40 : 20,
        vertical: 16,
      ),
      decoration: const BoxDecoration(
        gradient: AppTheme.heroGradient,
        border: Border(
          bottom: BorderSide(color: AppTheme.electricPink, width: 0.6),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const AppBrandMark(size: 36, showWordmark: true),
                ],
              ),
              if (isWide)
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text(
                        'Log In',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.crimsonBerry,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Row(
                        children: [
                          Text(
                            'Get Started',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isWide, bool isTablet) {
    if (isWide) {
      return Container(
        height: 520,
        decoration: BoxDecoration(
          gradient: AppTheme.heroGradient,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.electricPink.withValues(alpha: 0.55)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.crimsonBerry.withValues(alpha: 0.16),
              blurRadius: 26,
              spreadRadius: -8,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Hero Text
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.electricPink.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.electricPink),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flash_on, color: AppTheme.crimsonBerryLight, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'ALL-IN-ONE ATHLETIC ENGINE',
                            style: TextStyle(
                              color: AppTheme.crimsonBerryLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Push Limits.\nUnlock Your Power.',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Precision progressive overload, live GPS route runs, real-time macro fueling, and 24/7 AI coaching. 100% free with no subscription walls.',
                      style: TextStyle(
                        fontSize: 14.5,
                        color: AppTheme.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 14,
                      runSpacing: 12,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.fitness_center),
                          label: const Text('Start Training Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.electricPink,
                            elevation: 2,
                            shadowColor: AppTheme.electricPink,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Sign In to Account'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Right Hero Athlete Photo
            Expanded(
              flex: 5,
              child: SafeAthleticImage(
                imageUrl: AppImages.heroAthlete,
                fit: BoxFit.cover,
                height: double.infinity,
                overlay: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.deepPlum.withValues(alpha: 0.92),
                        AppTheme.crimsonBerry.withValues(alpha: 0.32),
                        Colors.transparent,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Mobile / Tablet Hero Card (matches the Figma visual)
    return Container(
      constraints: BoxConstraints(minHeight: isTablet ? 420 : 380),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.electricPink.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.crimsonBerry.withValues(alpha: 0.16),
            blurRadius: 22,
            spreadRadius: -8,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background athlete photography
          Positioned.fill(
            child: SafeAthleticImage(
              imageUrl: AppImages.pushLimitsBanner,
              fit: BoxFit.cover,
            ),
          ),
          // Deep dark gradient overlay for text readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.deepPlum.withValues(alpha: 0.88),
                    AppTheme.crimsonBerryDark.withValues(alpha: 0.62),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
          // Hero Text Content
          Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppTheme.crimsonGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.electricPink.withValues(alpha: 0.22),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Text(
                    '⚡ PRO PERFORMANCE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Push Limits.\nUnlock Your Power.',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Smart training for real results. Strength routines, GPS runs, precision diet & 24/7 AI guidance.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.crimsonBerry,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Get Started Free',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMetricsBanner(bool isWide) {
    final metrics = [
      {'label': 'Curated Exercises', 'val': '66+', 'icon': Icons.fitness_center},
      {'label': '1RM Calculation', 'val': 'Scientific', 'icon': Icons.bolt},
      {'label': 'GPS Route Map', 'val': 'Live OSM', 'icon': Icons.directions_run},
      {'label': 'Subscription', 'val': '100% Free', 'icon': Icons.lock_open},
    ];

    if (isWide) {
      return Row(
        children: metrics.map((m) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.slateCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.slateBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.crimsonBerry.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      m['icon'] as IconData,
                      color: AppTheme.crimsonBerryLight,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          m['val'] as String,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          m['label'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
            : ((availableWidth - 10) / 2).clamp(1.0, double.infinity);
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: metrics.map((m) {
            return SizedBox(
              width: cardWidth,
              child: Container(
                padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.slateCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.slateBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    m['icon'] as IconData,
                    color: AppTheme.crimsonBerryLight,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m['val'] as String,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          m['label'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        );
      },
    );
  }

  Widget _buildSectionHeader({
    required String badge,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.crimsonBerry.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.crimsonBerry.withValues(alpha: 0.5)),
          ),
          child: Text(
            badge,
            style: const TextStyle(
              color: AppTheme.crimsonBerryLight,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureGrid(BuildContext context, bool isWide, bool isTablet) {
    final features = [
      {
        'title': 'Battle Rope Waves & Heavy Lifts',
        'subtitle':
            'Smart strength routines covering Push/Pull/Legs with automated rest timers, haptic cues, and 1RM calculations.',
        'image': AppImages.battleRopes,
        'tag': 'STRENGTH & HYPERTROPHY',
        'icon': Icons.fitness_center,
        'stats': '66+ Exercises • 1RM Calculator',
      },
      {
        'title': 'Live Outdoor GPS Running',
        'subtitle':
            'Track outdoor mileage, pace, and calories burned with real-time OpenStreetMap route visualization.',
        'image': AppImages.runningOutdoor,
        'tag': 'CARDIO & GPS',
        'icon': Icons.directions_run,
        'stats': 'Live Pace • Route Visualizer',
      },
      {
        'title': 'Precision Macro Fueling',
        'subtitle':
            'Active food logging is strictly enabled for today, keeping habits accountable while past days remain preserved.',
        'image': AppImages.healthyNutrition,
        'tag': 'NUTRITION & MACROS',
        'icon': Icons.restaurant,
        'stats': 'Real-Time Calories • Strict Today-Only',
      },
      {
        'title': '24/7 OmniFit Gemini AI Coach',
        'subtitle':
            'Domain-guarded intelligence to guide hypertrophy, cutting, meal prep, and personalized workout routines with offline backup.',
        'image': AppImages.aiCoach,
        'tag': 'INTELLIGENT COACH',
        'icon': Icons.auto_awesome,
        'stats': 'Gemini AI • Offline Support',
      },
    ];

    if (isWide || isTablet) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          if (availableWidth <= 0) return const SizedBox.shrink();
          final isSingleCol = availableWidth < 300;
          final cardWidth = isSingleCol
              ? availableWidth
              : ((availableWidth - 20) / 2).clamp(1.0, double.infinity);
          return Wrap(
            spacing: 20,
            runSpacing: 20,
            children: features.map((f) {
              return SizedBox(
                width: cardWidth,
                child: _buildFeatureCard(context, f),
              );
            }).toList(),
          );
        },
      );
    }

    return Column(
      children: features.map((f) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: _buildFeatureCard(context, f),
        );
      }).toList(),
    );
  }

  Widget _buildFeatureCard(BuildContext context, Map<String, dynamic> f) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.slateCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.slateBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image header with tag badge
          Stack(
            children: [
              SafeAthleticImage(
                imageUrl: f['image'] as String,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.obsidianBlack.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.slateBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        f['icon'] as IconData,
                        color: AppTheme.crimsonBerryLight,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        f['tag'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 14,
                child: Text(
                  f['stats'] as String,
                  style: const TextStyle(
                    color: AppTheme.crimsonBerryLight,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f['title'] as String,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  f['subtitle'] as String,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppTheme.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.crimsonBerry,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: const Text(
                      'Explore Feature',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqList() {
    final faqs = [
      {
        'q': 'How does the Rest Timer work during workouts?',
        'a':
            'When you complete and check off a set in the Active Workout Tracker, the rest timer automatically triggers a 60s, 90s, or 120s countdown. It fires haptic vibrations and sound cues so you know exactly when to lift without staring at your phone.',
      },
      {
        'q': 'How are Personal Records (PR) and 1RM calculated?',
        'a':
            'OmniFit computes estimated 1-Rep Max using validated sports science formulas (Epley and Brzycki equations). When you break a personal best, an automatic celebratory PR badge is awarded and logged.',
      },
      {
        'q': 'Why can food entries only be logged for today?',
        'a':
            'To build sustainable daily nutrition habits and prevent retroactive data inaccuracies, food logging is strictly enabled for the current day. Past dates remain accessible as view-only historical logs.',
      },
      {
        'q': 'Does Running GPS work outdoors without additional devices?',
        'a':
            'Yes. OmniFit uses your device\'s built-in GPS and OpenStreetMap to calculate live distance, pace, elapsed time, and renders your route map directly on your screen.',
      },
      {
        'q': 'Is any payment or subscription required?',
        'a':
            'No. OmniFit is 100% free with no subscription tiers, paywalls, or advertisements. All features are completely unlocked for every athlete.',
      },
    ];

    return Column(
      children: faqs.map((faq) {
        return _FaqAccordionItem(
          question: faq['q']!,
          answer: faq['a']!,
        );
      }).toList(),
    );
  }

  Widget _buildCtaCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.crimsonBerry,
            AppTheme.crimsonBerryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.crimsonBerry.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.bolt, color: Colors.white, size: 40),
          const SizedBox(height: 14),
          const Text(
            'Ready To Elevate Your Training?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your athlete account in 30 seconds. No subscription, zero ads.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.crimsonBerry,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              );
            },
            child: const Text(
              'Get Started Now',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: AppTheme.crimsonBerry,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.fitness_center, color: AppTheme.crimsonBerryLight, size: 18),
            SizedBox(width: 8),
            Text(
              'OMNIFIT ATHLETICS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          '© 2026 OmniFit • Progressive Overload & Athletic Performance',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}

class _FaqAccordionItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqAccordionItem({
    required this.question,
    required this.answer,
  });

  @override
  State<_FaqAccordionItem> createState() => _FaqAccordionItemState();
}

class _FaqAccordionItemState extends State<_FaqAccordionItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.slateCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isExpanded ? AppTheme.crimsonBerry : AppTheme.slateBorder,
          width: 1.2,
        ),
      ),
      child: Material(
        color: AppTheme.slateCard,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.question,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _isExpanded
                            ? AppTheme.crimsonBerry
                            : AppTheme.obsidianBlack,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isExpanded
                              ? AppTheme.crimsonBerry
                              : AppTheme.slateBorder,
                        ),
                      ),
                      child: Icon(
                        _isExpanded ? Icons.remove : Icons.add,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      widget.answer,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: AppTheme.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ),
                  crossFadeState: _isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
