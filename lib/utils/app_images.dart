import 'package:flutter/material.dart';

class AppImages {
  // Hero & General Fitness Athletes (Pre-bundled Local Assets for 0ms loading)
  static const String heroAthlete = 'assets/images/hero_athlete.jpg';
  static const String pushLimitsBanner = 'assets/images/push_limits.jpg';

  // Strength & Lifting Exercises
  static const String battleRopes = 'assets/images/battle_ropes.jpg';
  static const String deadlift = 'assets/images/deadlift.jpg';
  static const String plankCore = 'assets/images/plank_core.jpg';
  static const String dumbbells = 'assets/images/dumbbells.jpg';

  // Running & Cardio
  static const String runningOutdoor = 'assets/images/running_outdoor.jpg';
  static const String sprinter = 'assets/images/sprinter.jpg';

  // Nutrition & Healthy Fueling
  static const String healthyNutrition = 'assets/images/healthy_nutrition.jpg';
  static const String mealPrep = 'assets/images/meal_prep.jpg';

  // AI Coach & High Tech Performance
  static const String aiCoach = 'assets/images/ai_coach.jpg';
}

/// Robust image widget with rounded corners, graceful gradient placeholder, and fallback
class SafeAthleticImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? overlay;

  const SafeAthleticImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.overlay,
  });

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF161822),
        borderRadius: borderRadius ?? BorderRadius.circular(16),
      ),
      child: const Center(
        child: Icon(
          Icons.fitness_center,
          color: Color(0xFF646A7E),
          size: 28,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLocalAsset = imageUrl.startsWith('assets/');

    Widget imageWidget = isLocalAsset
        ? Image.asset(
            imageUrl,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          )
        : Image.network(
            imageUrl,
            width: width,
            height: height,
            fit: fit,
            cacheWidth: 600,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: const Color(0xFF161822),
                  borderRadius: borderRadius ?? BorderRadius.circular(16),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFBA0C48)),
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          );

    if (overlay != null) {
      imageWidget = Stack(
        fit: StackFit.passthrough,
        children: [
          imageWidget,
          Positioned.fill(child: overlay!),
        ],
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }
}
