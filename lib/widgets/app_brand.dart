import 'package:flutter/material.dart';
import '../app/theme.dart';

class AppBrandMark extends StatefulWidget {
  final double size;
  final bool showWordmark;

  const AppBrandMark({
    super.key,
    this.size = 36,
    this.showWordmark = false,
  });

  @override
  State<AppBrandMark> createState() => _AppBrandMarkState();
}

class _AppBrandMarkState extends State<AppBrandMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppTheme.crimsonGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.crimsonBerry.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(Icons.bolt_rounded, color: Colors.white, size: size * 0.58),
    );

    final animatedMark = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.scale(
        scale: 0.96 + (_controller.value * 0.04),
        child: child,
      ),
      child: mark,
    );

    if (!widget.showWordmark) return animatedMark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        animatedMark,
        const SizedBox(width: 10),
        const Text(
          'OMNIFIT',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}
