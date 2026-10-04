import 'dart:math';
import 'package:flutter/material.dart';
import '../models/running_session_model.dart';
import '../utils/api_constants.dart';

/// Interactive public OpenStreetMap tile renderer.
///
/// Functions as a 100% free, keyless backup map provider that runs
/// seamlessly on all platforms (Android, iOS, Windows, macOS, Web)
/// without requiring Google Play Services or an active Google Maps API key.
class OpenStreetMapWidget extends StatefulWidget {
  final LatLngPoint center;
  final List<LatLngPoint> routePoints;
  final bool isLive;

  const OpenStreetMapWidget({
    super.key,
    required this.center,
    required this.routePoints,
    this.isLive = false,
  });

  @override
  State<OpenStreetMapWidget> createState() => _OpenStreetMapWidgetState();
}

class _OpenStreetMapWidgetState extends State<OpenStreetMapWidget> {
  double _zoom = 16.0;
  Offset _panOffset = Offset.zero;

  void _zoomIn() {
    setState(() {
      if (_zoom < 18.0) _zoom += 1.0;
    });
  }

  void _zoomOut() {
    setState(() {
      if (_zoom > 13.0) _zoom -= 1.0;
    });
  }

  void _recenter() {
    setState(() {
      _panOffset = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        final z = _zoom.round();
        final n = 1 << z; // 2^z

        // Slippy map tile calculations
        final centerLatRad = widget.center.latitude * pi / 180.0;
        final clampedLatRad = centerLatRad.clamp(-1.4844, 1.4844); // ~85 degrees

        final xFloat = (widget.center.longitude + 180.0) / 360.0 * n;
        final yFloat = (1.0 -
                log(tan(clampedLatRad) + 1.0 / cos(clampedLatRad)) / pi) /
            2.0 *
            n;

        final worldCenterX = xFloat * 256.0 - _panOffset.dx;
        final worldCenterY = yFloat * 256.0 - _panOffset.dy;

        final viewLeft = worldCenterX - width / 2.0;
        final viewTop = worldCenterY - height / 2.0;
        final viewRight = worldCenterX + width / 2.0;
        final viewBottom = worldCenterY + height / 2.0;

        final minTileX = (viewLeft / 256.0).floor();
        final maxTileX = (viewRight / 256.0).floor();
        final minTileY = (viewTop / 256.0).floor().clamp(0, n - 1);
        final maxTileY = (viewBottom / 256.0).floor().clamp(0, n - 1);

        final List<Widget> tileWidgets = [];

        for (int tx = minTileX; tx <= maxTileX; tx++) {
          final wrappedTx = ((tx % n) + n) % n;
          for (int ty = minTileY; ty <= maxTileY; ty++) {
            final tileLeft = tx * 256.0 - viewLeft;
            final tileTop = ty * 256.0 - viewTop;

            final tileUrl = ApiConstants.openStreetMapTileUrl
                .replaceAll('{z}', '$z')
                .replaceAll('{x}', '$wrappedTx')
                .replaceAll('{y}', '$ty');

            tileWidgets.add(
              Positioned(
                left: tileLeft,
                top: tileTop,
                width: 256.0,
                height: 256.0,
                child: Image.network(
                  tileUrl,
                  headers: const {'User-Agent': ApiConstants.openStreetMapUserAgent},
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFFE2E8F0),
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 24, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            );
          }
        }

        return GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _panOffset += details.delta;
            });
          },
          child: ClipRect(
            child: Stack(
              children: [
                // Background Tile Layer
                ...tileWidgets,

                // Polyline & Marker Canvas
                Positioned.fill(
                  child: CustomPaint(
                    painter: _OsmRoutePainter(
                      routePoints: widget.routePoints,
                      currentPosition: widget.center,
                      viewLeft: viewLeft,
                      viewTop: viewTop,
                      zoomInt: z,
                    ),
                  ),
                ),

                // Controls (Zoom in / out / recenter)
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_panOffset != Offset.zero) ...[
                        FloatingActionButton.small(
                          heroTag: 'osm_recenter',
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue,
                          onPressed: _recenter,
                          child: const Icon(Icons.my_location, size: 20),
                        ),
                        const SizedBox(height: 8),
                      ],
                      FloatingActionButton.small(
                        heroTag: 'osm_zoom_in',
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        onPressed: _zoomIn,
                        child: const Icon(Icons.add, size: 20),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'osm_zoom_out',
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        onPressed: _zoomOut,
                        child: const Icon(Icons.remove, size: 20),
                      ),
                    ],
                  ),
                ),

                // OpenStreetMap Legal Attribution & Status Badge
                Positioned(
                  left: 10,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.public, color: Colors.lightGreenAccent, size: 12),
                        SizedBox(width: 4),
                        Text(
                          '© OpenStreetMap contributors',
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OsmRoutePainter extends CustomPainter {
  final List<LatLngPoint> routePoints;
  final LatLngPoint currentPosition;
  final double viewLeft;
  final double viewTop;
  final int zoomInt;

  _OsmRoutePainter({
    required this.routePoints,
    required this.currentPosition,
    required this.viewLeft,
    required this.viewTop,
    required this.zoomInt,
  });

  Offset _latLngToScreen(LatLngPoint point) {
    final n = 1 << zoomInt;
    final latRad = point.latitude * pi / 180.0;
    final clampedLat = latRad.clamp(-1.4844, 1.4844);

    final xFloat = (point.longitude + 180.0) / 360.0 * n;
    final yFloat = (1.0 - log(tan(clampedLat) + 1.0 / cos(clampedLat)) / pi) /
        2.0 *
        n;

    return Offset(
      xFloat * 256.0 - viewLeft,
      yFloat * 256.0 - viewTop,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (routePoints.isNotEmpty) {
      final path = Path();
      final firstPt = _latLngToScreen(routePoints.first);
      path.moveTo(firstPt.dx, firstPt.dy);

      for (int i = 1; i < routePoints.length; i++) {
        final pt = _latLngToScreen(routePoints[i]);
        path.lineTo(pt.dx, pt.dy);
      }

      // Outer glow polyline
      final glowPaint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.4)
        ..strokeWidth = 8.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, glowPaint);

      // Core route polyline
      final corePaint = Paint()
        ..color = Colors.deepOrangeAccent
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, corePaint);

      // Start pin (Green)
      final startPt = firstPt;
      canvas.drawCircle(
        startPt,
        6,
        Paint()
          ..color = Colors.green
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        startPt,
        10,
        Paint()
          ..color = Colors.green.withValues(alpha: 0.3)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }

    // Current position indicator (Blue pulsing runner marker)
    final currPt = _latLngToScreen(currentPosition);
    canvas.drawCircle(
      currPt,
      14,
      Paint()
        ..color = Colors.blue.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      currPt,
      8,
      Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      currPt,
      8,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _OsmRoutePainter oldDelegate) {
    return oldDelegate.routePoints.length != routePoints.length ||
        oldDelegate.viewLeft != viewLeft ||
        oldDelegate.viewTop != viewTop ||
        oldDelegate.zoomInt != zoomInt ||
        oldDelegate.currentPosition.latitude != currentPosition.latitude ||
        oldDelegate.currentPosition.longitude != currentPosition.longitude;
  }
}
