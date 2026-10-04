import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/running_session_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/running_provider.dart';
import '../../widgets/open_street_map_widget.dart';
import '../../widgets/route_track_visualizer.dart';
import 'run_details_screen.dart';

enum MapEngine {
  openStreetMap,
  googleMaps,
  radarVisualizer,
}

class RunningScreen extends StatefulWidget {
  const RunningScreen({super.key});

  @override
  State<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends State<RunningScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GoogleMapController? _mapController;

  late MapEngine _currentEngine;

  bool get _isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Default to OpenStreetMap as the reliable zero-config map provider.
    _currentEngine = MapEngine.openStreetMap;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().userProfile;
      if (user != null) {
        context.read<RunningProvider>().loadHistory(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final runningProvider = context.watch<RunningProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Running & GPS Tracker'),
        actions: [
          PopupMenuButton<MapEngine>(
            icon: const Icon(Icons.layers_outlined),
            tooltip: 'Select Map Engine',
            initialValue: _currentEngine,
            onSelected: (engine) {
              if (engine == MapEngine.googleMaps && _isDesktop) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Google Maps native SDK requires Android, iOS, or Web. Using OpenStreetMap on desktop.',
                    ),
                  ),
                );
                return;
              }
              setState(() {
                _currentEngine = engine;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: MapEngine.openStreetMap,
                child: Row(
                  children: [
                    Icon(Icons.public, color: Colors.green),
                    SizedBox(width: 10),
                    Text('OpenStreetMap (Public API)'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: MapEngine.googleMaps,
                enabled: !_isDesktop,
                child: Row(
                  children: [
                    Icon(
                      Icons.map,
                      color: _isDesktop ? Colors.grey : Colors.blue,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isDesktop
                          ? 'Google Maps (Mobile Only)'
                          : 'Google Maps (Platform)',
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: MapEngine.radarVisualizer,
                child: Row(
                  children: [
                    Icon(Icons.radar, color: Colors.deepOrange),
                    SizedBox(width: 10),
                    Text('GPS Radar (Vector Canvas)'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Live Tracker'),
            Tab(text: 'Run History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLiveTrackerTab(runningProvider),
          _buildHistoryTab(runningProvider),
        ],
      ),
    );
  }

  Widget _buildLiveTrackerTab(RunningProvider runningProvider) {
    final currentPos = runningProvider.currentPosition;
    final LatLng cameraTarget = currentPos != null
        ? LatLng(currentPos.latitude, currentPos.longitude)
        : const LatLng(37.7749, -122.4194); // Default map target

    final routeCoords = runningProvider.routePoints
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    // A valid Polyline requires at least 2 points
    final Set<Polyline> polylines = {
      if (routeCoords.length >= 2)
        Polyline(
          polylineId: const PolylineId('active_run_route'),
          points: routeCoords,
          color: Colors.blue,
          width: 5,
        ),
    };

    final Set<Marker> markers = {
      if (currentPos != null)
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(currentPos.latitude, currentPos.longitude),
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
    };

    final centerPoint = currentPos != null
        ? LatLngPoint(latitude: currentPos.latitude, longitude: currentPos.longitude)
        : (runningProvider.routePoints.isNotEmpty
            ? runningProvider.routePoints.last
            : const LatLngPoint(latitude: 37.7749, longitude: -122.4194));

    Widget mapWidget;
    String engineBadge;
    IconData engineIcon;

    switch (_currentEngine) {
      case MapEngine.googleMaps:
        if (_isDesktop) {
          mapWidget = OpenStreetMapWidget(
            center: centerPoint,
            routePoints: runningProvider.routePoints,
            isLive: true,
          );
          engineBadge = 'OpenStreetMap (Desktop)';
          engineIcon = Icons.public;
        } else {
          mapWidget = _SafeGoogleMapView(
            cameraTarget: cameraTarget,
            onMapCreated: (controller) => _mapController = controller,
            polylines: polylines,
            markers: markers,
            onFallback: () {
              setState(() {
                _currentEngine = MapEngine.openStreetMap;
              });
            },
          );
          engineBadge = 'Google Maps';
          engineIcon = Icons.map;
        }
        break;

      case MapEngine.radarVisualizer:
        mapWidget = RouteTrackVisualizer(
          routePoints: runningProvider.routePoints,
          isLive: true,
        );
        engineBadge = 'GPS Radar';
        engineIcon = Icons.radar;
        break;

      case MapEngine.openStreetMap:
        mapWidget = OpenStreetMapWidget(
          center: centerPoint,
          routePoints: runningProvider.routePoints,
          isLive: true,
        );
        engineBadge = 'OpenStreetMap';
        engineIcon = Icons.public;
        break;
    }

    return Stack(
      children: [
        // Main Map Layer
        Positioned.fill(child: mapWidget),

        // Map Provider Badge (clickable to toggle)
        Positioned(
          top: 12,
          right: 16,
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (_currentEngine == MapEngine.openStreetMap) {
                  _currentEngine =
                      _isDesktop ? MapEngine.radarVisualizer : MapEngine.googleMaps;
                } else if (_currentEngine == MapEngine.googleMaps) {
                  _currentEngine = MapEngine.radarVisualizer;
                } else {
                  _currentEngine = MapEngine.openStreetMap;
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(engineIcon, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    engineBadge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Permission / Error banner if needed
        if (runningProvider.errorMessage != null &&
            !runningProvider.hasActiveRun)
          Positioned(
            top: 48,
            left: 16,
            right: 16,
            child: Card(
              color: Colors.amber[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        runningProvider.errorMessage!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Live Dashboard Card
        Positioned(
          top: runningProvider.errorMessage != null ? 100 : 50,
          left: 16,
          right: 16,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildLiveMetricColumn(
                        'DISTANCE',
                        runningProvider.formattedDistance,
                        Colors.blue,
                      ),
                      Container(height: 36, width: 1, color: Colors.grey[300]),
                      _buildLiveMetricColumn(
                        'DURATION',
                        runningProvider.formattedDuration,
                        Colors.deepOrange,
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildLiveMetricColumn(
                        'AVG PACE',
                        runningProvider.currentPace,
                        Colors.purple,
                      ),
                      Container(height: 36, width: 1, color: Colors.grey[300]),
                      _buildLiveMetricColumn(
                        'CALORIES',
                        '~${runningProvider.estimatedCalories} kcal',
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Control Buttons at Bottom
        Positioned(
          bottom: 24,
          left: 24,
          right: 24,
          child: _buildControlsRow(runningProvider),
        ),
      ],
    );
  }

  Widget _buildLiveMetricColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildControlsRow(RunningProvider provider) {
    if (!provider.hasActiveRun) {
      return SizedBox(
        height: 54,
        child: ElevatedButton.icon(
          onPressed: () async {
            final success = await provider.startRun();
            if (success &&
                provider.currentPosition != null &&
                _mapController != null) {
              _mapController!.animateCamera(
                CameraUpdate.newLatLng(
                  LatLng(
                    provider.currentPosition!.latitude,
                    provider.currentPosition!.longitude,
                  ),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 4,
          ),
          icon: const Icon(Icons.directions_run, size: 28),
          label: const Text(
            'START RUN',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Row(
      children: [
        // Pause / Resume Button
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                if (provider.isRunning) {
                  provider.pauseRun();
                } else {
                  provider.resumeRun();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    provider.isRunning ? Colors.amber[700] : Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              icon: Icon(
                provider.isRunning ? Icons.pause : Icons.play_arrow,
                size: 24,
              ),
              label: Text(
                provider.isRunning ? 'PAUSE' : 'RESUME',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Finish Button
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _confirmFinishRun(provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              icon: const Icon(Icons.stop, size: 24),
              label: const Text(
                'FINISH',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmFinishRun(RunningProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finish Running Session?'),
        content: Text(
          'Total distance: ${provider.formattedDistance}\nDuration: ${provider.formattedDuration}\n\nWould you like to save this run to your history?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.cancelRun();
            },
            child: const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final userId = context.read<AuthProvider>().userId;
              final session = await provider.stopAndSaveRun(userId);
              if (session != null && mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RunDetailsScreen(session: session),
                  ),
                );
              }
            },
            child: const Text('Save Run'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(RunningProvider provider) {
    if (provider.isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    final userId = context.read<AuthProvider>().userId;

    return RefreshIndicator(
      onRefresh: () => provider.loadHistory(userId),
      child: CustomScrollView(
        slivers: [
          // Aggregate Stats Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overall Performance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Distance',
                          '${provider.totalDistanceKm.toStringAsFixed(1)} km',
                          Icons.straighten,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Runs',
                          '${provider.totalRuns}',
                          Icons.directions_run,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Best Pace',
                          provider.bestPace,
                          Icons.speed,
                          Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSummaryCard(
                          'Longest Run',
                          '${provider.longestRunKm.toStringAsFixed(1)} km',
                          Icons.emoji_events,
                          Colors.amber[800]!,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Run History',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // Run List
          if (provider.history.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.directions_run,
                      size: 54,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    const Text('No runs recorded yet.'),
                    const SizedBox(height: 6),
                    Text(
                      'Tap "Start Run" in the live tracker tab to log your first session!',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final run = provider.history[index];
                  final formattedDate =
                      DateFormat('MMM d, yyyy • h:mm a').format(run.startTime);

                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.withValues(alpha: 0.1),
                        child: const Icon(
                          Icons.directions_run,
                          color: Colors.blue,
                        ),
                      ),
                      title: Text(
                        run.formattedDistance,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '$formattedDate\n${run.formattedDuration} • ${run.averagePace} • ~${run.calories} kcal',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RunDetailsScreen(session: run),
                          ),
                        );
                      },
                    ),
                  );
                },
                childCount: provider.history.length,
              ),
            ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A crash-resilient wrapper around GoogleMap that never throws a red screen
class _SafeGoogleMapView extends StatefulWidget {
  final LatLng cameraTarget;
  final ValueChanged<GoogleMapController>? onMapCreated;
  final Set<Polyline> polylines;
  final Set<Marker> markers;
  final VoidCallback onFallback;

  const _SafeGoogleMapView({
    required this.cameraTarget,
    this.onMapCreated,
    required this.polylines,
    required this.markers,
    required this.onFallback,
  });

  @override
  State<_SafeGoogleMapView> createState() => _SafeGoogleMapViewState();
}

class _SafeGoogleMapViewState extends State<_SafeGoogleMapView> {
  @override
  Widget build(BuildContext context) {
    try {
      return GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.cameraTarget,
          zoom: 16.0,
        ),
        onMapCreated: widget.onMapCreated,
        polylines: widget.polylines,
        markers: widget.markers,
        myLocationEnabled: false, // Prevents Android SecurityException crash
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
      );
    } catch (_) {
      return Container(
        color: const Color(0xFF0F172A),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.orangeAccent),
              const SizedBox(height: 12),
              const Text(
                'Google Maps Unavailable',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Google Maps could not load on this platform or device.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                icon: const Icon(Icons.public),
                label: const Text('Switch to OpenStreetMap'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: widget.onFallback,
              ),
            ],
          ),
        ),
      );
    }
  }
}
