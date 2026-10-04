class LatLngPoint {
  final double latitude;
  final double longitude;

  const LatLngPoint({
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory LatLngPoint.fromMap(Map<String, dynamic> map) {
    return LatLngPoint(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
    );
  }
}

class RunningSessionModel {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final int durationSeconds;
  final double distanceKm;
  final String averagePace;
  final int calories;
  final List<LatLngPoint> route;
  final String? notes;

  RunningSessionModel({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.distanceKm,
    required this.averagePace,
    required this.calories,
    required this.route,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationSeconds': durationSeconds,
      'distanceKm': distanceKm,
      'averagePace': averagePace,
      'calories': calories,
      'route': route.map((p) => p.toMap()).toList(),
      'notes': notes ?? '',
    };
  }

  factory RunningSessionModel.fromMap(String id, Map<String, dynamic> map) {
    List<LatLngPoint> points = [];
    if (map['route'] != null && map['route'] is List) {
      points = (map['route'] as List)
          .map((item) => LatLngPoint.fromMap(item as Map<String, dynamic>))
          .toList();
    }

    return RunningSessionModel(
      id: id,
      startTime: map['startTime'] != null
          ? DateTime.tryParse(map['startTime'] as String) ?? DateTime.now()
          : DateTime.now(),
      endTime: map['endTime'] != null
          ? DateTime.tryParse(map['endTime'] as String) ?? DateTime.now()
          : DateTime.now(),
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0.0,
      averagePace: map['averagePace'] as String? ?? '0:00 /km',
      calories: (map['calories'] as num?)?.toInt() ?? 0,
      route: points,
      notes: map['notes'] as String?,
    );
  }

  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    final hours = minutes ~/ 60;
    if (hours > 0) {
      final remMinutes = minutes % 60;
      return '${hours}h ${remMinutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedDistance => '${distanceKm.toStringAsFixed(2)} km';

  /// Calculate calories based on distance and weight (default 70kg if unprovided)
  static int estimateCalories(double distanceKm, [double weightKg = 70.0]) {
    // Standard approximation: ~1.036 kcal per kg per km
    return (distanceKm * weightKg * 1.036).round();
  }

  /// Calculate pace string (e.g. 5:30 /km) from seconds and distance in km
  static String calculatePace(int seconds, double distanceKm) {
    if (distanceKm <= 0.01 || seconds <= 0) return '0:00 /km';
    final paceInSeconds = (seconds / distanceKm).round();
    final mins = paceInSeconds ~/ 60;
    final secs = paceInSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')} /km';
  }
}
