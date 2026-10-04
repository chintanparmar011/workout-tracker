import 'dart:math';
import 'package:flutter/material.dart';
import '../models/running_session_model.dart';

class RouteTrackVisualizer extends StatelessWidget {
  final List<LatLngPoint> routePoints;
  final bool isLive;

  const RouteTrackVisualizer({
    super.key,
    required this.routePoints,
    this.isLive = false,
  });

  @override
  Widget build(BuildContext context) {
    if (routePoints.isEmpty) {
      return Container(
        color: const Color(0xFF1E293B),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.gps_fixed,
                  size: 48,
                  color: Colors.lightBlueAccent,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'GPS Route Visualizer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isLive
                    ? 'Acquiring GPS signal...\nTap "START RUN" to begin recording your path.'
                    : 'No GPS route points recorded for this run.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFF0F172A),
      child: Stack(
        children: [
          // Background GPS Grid
          Positioned.fill(
            child: CustomPaint(
              painter: _GpsGridPainter(),
            ),
          ),

          // Route Path Line
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: CustomPaint(
                painter: _RoutePathPainter(routePoints),
              ),
            ),
          ),

          // Watermark / Badge
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.route,
                    size: 14,
                    color: isLive ? Colors.greenAccent : Colors.orangeAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${routePoints.length} GPS Points',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GpsGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    const double step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoutePathPainter extends CustomPainter {
  final List<LatLngPoint> points;

  _RoutePathPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    if (points.length == 1) {
      final center = Offset(size.width / 2, size.height / 2);
      final dotPaint = Paint()
        ..color = Colors.blueAccent
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 8, dotPaint);
      return;
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final latSpan = max(maxLat - minLat, 0.0001);
    final lngSpan = max(maxLng - minLng, 0.0001);

    Offset toCanvas(LatLngPoint p) {
      // Invert latitude because canvas Y increases downwards
      final normY = 1.0 - ((p.latitude - minLat) / latSpan);
      final normX = (p.longitude - minLng) / lngSpan;
      return Offset(normX * size.width, normY * size.height);
    }

    // Draw Route Path
    final path = Path();
    final firstOffset = toCanvas(points.first);
    path.moveTo(firstOffset.dx, firstOffset.dy);

    for (int i = 1; i < points.length; i++) {
      final pt = toCanvas(points[i]);
      path.lineTo(pt.dx, pt.dy);
    }

    // Glow paint
    final glowPaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.3)
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, glowPaint);

    // Main line paint
    final linePaint = Paint()
      ..color = Colors.deepOrangeAccent
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);

    // Start marker (Green)
    final startPt = firstOffset;
    final startPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(startPt, 6, startPaint);
    canvas.drawCircle(
      startPt,
      10,
      Paint()
        ..color = Colors.greenAccent.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // End / Current marker (Red / Azure)
    final endPt = toCanvas(points.last);
    final endPaint = Paint()
      ..color = Colors.lightBlueAccent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(endPt, 7, endPaint);
    canvas.drawCircle(
      endPt,
      12,
      Paint()
        ..color = Colors.lightBlueAccent.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _RoutePathPainter oldDelegate) {
    return oldDelegate.points.length != points.length;
  }
}
