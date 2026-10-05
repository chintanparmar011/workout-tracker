import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/running_session_model.dart';
import '../../utils/google_maps_checker.dart';
import '../../widgets/open_street_map_widget.dart';
import '../../widgets/route_track_visualizer.dart';
import '../../widgets/workout_story_card.dart';

class RunDetailsScreen extends StatefulWidget {
  final RunningSessionModel session;

  const RunDetailsScreen({super.key, required this.session});

  @override
  State<RunDetailsScreen> createState() => _RunDetailsScreenState();
}

class _RunDetailsScreenState extends State<RunDetailsScreen> {
  // 0: OpenStreetMap (Public backup), 1: Google Maps (if supported), 2: GPS Radar
  int _viewMode = 0;

  bool get _isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  void initState() {
    super.initState();
    _viewMode = 0; // Default to OpenStreetMap public backup
  }

  @override
  Widget build(BuildContext context) {
    final routeCoordinates = widget.session.route
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    final hasMapData = routeCoordinates.isNotEmpty;
    final initialCamera = hasMapData
        ? CameraPosition(
            target: routeCoordinates.first,
            zoom: 15.0,
          )
        : const CameraPosition(
            target: LatLng(0, 0),
            zoom: 2,
          );

    final Set<Polyline> polylines =
        (hasMapData && routeCoordinates.length >= 2)
            ? {
                Polyline(
                  polylineId: const PolylineId('run_route'),
                  points: routeCoordinates,
                  color: Colors.deepOrange,
                  width: 5,
                ),
              }
            : {};

    final Set<Marker> markers = {};
    if (hasMapData) {
      markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: routeCoordinates.first,
          infoWindow: const InfoWindow(title: 'Start'),
          icon: kIsWeb
              ? BitmapDescriptor.defaultMarker
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
      if (routeCoordinates.length > 1) {
        markers.add(
          Marker(
            markerId: const MarkerId('end'),
            position: routeCoordinates.last,
            infoWindow: const InfoWindow(title: 'Finish'),
            icon: kIsWeb
                ? BitmapDescriptor.defaultMarker
                : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      }
    }

    final formattedDate =
        DateFormat('EEEE, MMM d, yyyy • h:mm a').format(widget.session.startTime);

    final centerPoint = widget.session.route.isNotEmpty
        ? widget.session.route.first
        : const LatLngPoint(latitude: 37.7749, longitude: -122.4194);

    final canUseGoogleMaps = !_isDesktop && (!kIsWeb || isGoogleMapsReady());

    Widget mapDisplayWidget;
    String badgeText;
    IconData badgeIcon;

    if (_viewMode == 0) {
      mapDisplayWidget = OpenStreetMapWidget(
        center: centerPoint,
        routePoints: widget.session.route,
      );
      badgeText = 'OpenStreetMap';
      badgeIcon = Icons.public;
    } else if (_viewMode == 1 && canUseGoogleMaps) {
      mapDisplayWidget = hasMapData
          ? GoogleMap(
              initialCameraPosition: initialCamera,
              polylines: polylines,
              markers: markers,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
            )
          : Container(
              color: Colors.grey[200],
              child: const Center(child: Text('No GPS data')),
            );
      badgeText = 'Google Maps';
      badgeIcon = Icons.map;
    } else {
      mapDisplayWidget = RouteTrackVisualizer(routePoints: widget.session.route);
      badgeText = 'GPS Radar';
      badgeIcon = Icons.radar;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Run Summary'),
        actions: [
          if (hasMapData)
            IconButton(
              icon: Icon(badgeIcon),
              tooltip: 'Switch Map View ($badgeText)',
              onPressed: () {
                setState(() {
                  if (_viewMode == 0) {
                    _viewMode = canUseGoogleMaps ? 1 : 2;
                  } else if (_viewMode == 1) {
                    _viewMode = 2;
                  } else {
                    _viewMode = 0;
                  }
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Map / Visualizer Header
            SizedBox(
              height: 280,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(child: mapDisplayWidget),
                  Positioned(
                    top: 10,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badgeIcon, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            badgeText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Big Stats Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          context,
                          icon: Icons.straighten,
                          title: 'Distance',
                          value: widget.session.formattedDistance,
                          color: Colors.deepOrange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricTile(
                          context,
                          icon: Icons.timer,
                          title: 'Duration',
                          value: widget.session.formattedDuration,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          context,
                          icon: Icons.speed,
                          title: 'Avg Pace',
                          value: widget.session.averagePace,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricTile(
                          context,
                          icon: Icons.local_fire_department,
                          title: 'Calories',
                          value: '~${widget.session.calories} kcal',
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),

                  if (widget.session.notes != null &&
                      widget.session.notes!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('Notes',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(widget.session.notes!,
                        style: TextStyle(color: Colors.grey[800], fontSize: 14)),
                  ],
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB4F000),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.auto_awesome, size: 20),
                    label: const Text(
                      'Share Run Story',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    onPressed: () {
                      showWorkoutStoryModal(
                        context,
                        runSession: widget.session,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
        ],
      ),
    );
  }
}
