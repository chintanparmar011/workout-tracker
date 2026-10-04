import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/running_session_model.dart';
import '../services/firestore_service.dart';

enum RunState { initial, running, paused, completed }

class RunningProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  RunState _runState = RunState.initial;
  RunState get runState => _runState;

  bool get isRunning => _runState == RunState.running;
  bool get isPaused => _runState == RunState.paused;
  bool get hasActiveRun => _runState == RunState.running || _runState == RunState.paused;

  DateTime? _startTime;
  DateTime? get startTime => _startTime;

  int _durationSeconds = 0;
  int get durationSeconds => _durationSeconds;

  double _distanceMeters = 0.0;
  double get distanceMeters => _distanceMeters;
  double get distanceKm => _distanceMeters / 1000.0;

  final List<LatLngPoint> _routePoints = [];
  List<LatLngPoint> get routePoints => List.unmodifiable(_routePoints);

  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  Timer? _timer;
  StreamSubscription<Position>? _positionSubscription;

  // History & Summary Stats
  List<RunningSessionModel> _history = [];
  List<RunningSessionModel> get history => List.unmodifiable(_history);

  bool _isLoadingHistory = false;
  bool get isLoadingHistory => _isLoadingHistory;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Aggregate Stats
  double _totalDistanceKm = 0.0;
  double get totalDistanceKm => _totalDistanceKm;

  int _totalRuns = 0;
  int get totalRuns => _totalRuns;

  String _bestPace = '0:00 /km';
  String get bestPace => _bestPace;

  double _longestRunKm = 0.0;
  double get longestRunKm => _longestRunKm;

  String get formattedDuration {
    final minutes = _durationSeconds ~/ 60;
    final seconds = _durationSeconds % 60;
    final hours = minutes ~/ 60;
    if (hours > 0) {
      final remMinutes = minutes % 60;
      return '${hours}h ${remMinutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedDistance => '${distanceKm.toStringAsFixed(2)} km';

  String get currentPace => RunningSessionModel.calculatePace(_durationSeconds, distanceKm);

  int get estimatedCalories => RunningSessionModel.estimateCalories(distanceKm);

  /// Check & request location permission
  Future<bool> checkLocationPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _errorMessage = 'Location services are disabled on your device.';
      notifyListeners();
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _errorMessage = 'Location permission was denied.';
        notifyListeners();
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _errorMessage = 'Location permissions are permanently denied in device settings.';
      notifyListeners();
      return false;
    }

    _errorMessage = null;
    return true;
  }

  /// Start a new run session
  Future<bool> startRun() async {
    final hasPermission = await checkLocationPermissions();
    if (!hasPermission) return false;

    _resetActiveRunState();
    _runState = RunState.running;
    _startTime = DateTime.now();

    // Get initial fix
    try {
      final initialPos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      _currentPosition = initialPos;
      _routePoints.add(LatLngPoint(
        latitude: initialPos.latitude,
        longitude: initialPos.longitude,
      ));
    } catch (_) {
      // Continue anyway, position stream will provide points
    }

    _startTimer();
    _startLocationStream();

    notifyListeners();
    return true;
  }

  /// Pause current run
  void pauseRun() {
    if (_runState != RunState.running) return;
    _runState = RunState.paused;
    _timer?.cancel();
    _positionSubscription?.pause();
    notifyListeners();
  }

  /// Resume paused run
  void resumeRun() {
    if (_runState != RunState.paused) return;
    _runState = RunState.running;
    _startTimer();
    _positionSubscription?.resume();
    notifyListeners();
  }

  /// Stop current run and save to Firestore
  Future<RunningSessionModel?> stopAndSaveRun(String userId, {double userWeightKg = 70.0}) async {
    if (!hasActiveRun) return null;

    _timer?.cancel();
    _positionSubscription?.cancel();
    _runState = RunState.completed;

    final endTime = DateTime.now();
    final calories = RunningSessionModel.estimateCalories(distanceKm, userWeightKg);
    final paceStr = currentPace;

    final session = RunningSessionModel(
      id: '',
      startTime: _startTime ?? DateTime.now(),
      endTime: endTime,
      durationSeconds: _durationSeconds,
      distanceKm: distanceKm,
      averagePace: paceStr,
      calories: calories,
      route: List.from(_routePoints),
    );

    if (userId.isNotEmpty) {
      await _firestoreService.saveRunningSession(userId, session);
      await loadHistory(userId);
    }

    _resetActiveRunState();
    notifyListeners();
    return session;
  }

  /// Cancel active run without saving
  void cancelRun() {
    _timer?.cancel();
    _positionSubscription?.cancel();
    _resetActiveRunState();
    notifyListeners();
  }

  /// Load user running history & calculate summary statistics
  Future<void> loadHistory(String userId) async {
    if (userId.isEmpty) return;
    _isLoadingHistory = true;
    notifyListeners();

    _history = await _firestoreService.getRunningHistory(userId);
    _calculateStats();

    _isLoadingHistory = false;
    notifyListeners();
  }

  void _calculateStats() {
    if (_history.isEmpty) {
      _totalDistanceKm = 0.0;
      _totalRuns = 0;
      _bestPace = '0:00 /km';
      _longestRunKm = 0.0;
      return;
    }

    _totalRuns = _history.length;
    _totalDistanceKm = _history.fold(0.0, (sum, run) => sum + run.distanceKm);

    double maxDist = 0.0;
    int bestPaceSeconds = 999999;

    for (final run in _history) {
      if (run.distanceKm > maxDist) {
        maxDist = run.distanceKm;
      }

      if (run.distanceKm > 0.1 && run.durationSeconds > 0) {
        final secPerKm = (run.durationSeconds / run.distanceKm).round();
        if (secPerKm < bestPaceSeconds && secPerKm > 60) {
          bestPaceSeconds = secPerKm;
        }
      }
    }

    _longestRunKm = maxDist;
    if (bestPaceSeconds < 999999) {
      final m = bestPaceSeconds ~/ 60;
      final s = bestPaceSeconds % 60;
      _bestPace = '$m:${s.toString().padLeft(2, '0')} /km';
    } else {
      _bestPace = 'N/A';
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _durationSeconds++;
      notifyListeners();
    });
  }

  void _startLocationStream() {
    _positionSubscription?.cancel();
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (_runState != RunState.running) return;

      if (_currentPosition != null) {
        final delta = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        // Only accumulate reasonable movements (e.g. > 2m and < 100m in update cycle)
        if (delta >= 2.0 && delta < 200.0) {
          _distanceMeters += delta;
        }
      }

      _currentPosition = position;
      _routePoints.add(LatLngPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      ));

      notifyListeners();
    }, onError: (_) {
      // Ignore position stream errors gracefully
    });
  }

  void _resetActiveRunState() {
    _runState = RunState.initial;
    _startTime = null;
    _durationSeconds = 0;
    _distanceMeters = 0.0;
    _routePoints.clear();
    _currentPosition = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }
}
