import 'package:flutter/material.dart';

/// Professional Google Sign-In Button with accurate 4-color Google G icon
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.text = 'Continue with Google',
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E212E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF2E3346),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CustomPaint(painter: _GoogleIconPainter()),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Precise vector painter for official 4-colored Google 'G' logo
class _GoogleIconPainter extends CustomPainter {
  const _GoogleIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Offset center = Offset(w / 2, h / 2);
    final double radius = w / 2;

    final paintBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final paintGreen = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    final paintYellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    final paintRed = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;

    // Draw Google G arcs and bar
    final pathBlue = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(w, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        0,
        1.0,
        false,
      )
      ..lineTo(center.dx, center.dy)
      ..close();

    final pathGreen = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        1.0,
        1.1,
        false,
      )
      ..lineTo(center.dx, center.dy)
      ..close();

    final pathYellow = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        2.1,
        1.2,
        false,
      )
      ..lineTo(center.dx, center.dy)
      ..close();

    final pathRed = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        3.3,
        1.6,
        false,
      )
      ..lineTo(center.dx, center.dy)
      ..close();

    canvas.drawPath(pathBlue, paintBlue);
    canvas.drawPath(pathGreen, paintGreen);
    canvas.drawPath(pathYellow, paintYellow);
    canvas.drawPath(pathRed, paintRed);

    // Inner cutout circle to make it a ring
    final innerCutout = Paint()..color = const Color(0xFF1E212E);
    canvas.drawCircle(center, radius * 0.52, innerCutout);

    // Right horizontal bar of 'G'
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(center.dx - 1, center.dy - radius * 0.22, w - 1, center.dy + radius * 0.22),
      const Radius.circular(2),
    );
    canvas.drawRRect(barRect, paintBlue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
