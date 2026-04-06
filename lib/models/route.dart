class RouteInfo {
  final List<Map<String, double>> coordinates;
  final double distanceMeters;
  final double durationSeconds;
  final List<double> elevations;
  final List<double> gradients;
  final double maxElevation;
  final double minElevation;
  final double maxGradient;

  RouteInfo({
    required this.coordinates,
    required this.distanceMeters,
    required this.durationSeconds,
    this.elevations = const [],
    this.gradients = const [],
    this.maxElevation = 0,
    this.minElevation = 0,
    this.maxGradient = 0,
  });

  String get distanceKm => (distanceMeters / 1000).toStringAsFixed(1);
  String get durationMinutes => (durationSeconds / 60).toStringAsFixed(0);
  String get displayInfo => '$distanceKm km • $durationMinutes min';
  String get elevationGain {
    if (elevations.isEmpty) return 'N/A';
    double gain = 0;
    for (int i = 1; i < elevations.length; i++) {
      final diff = elevations[i] - elevations[i - 1];
      if (diff > 0) gain += diff;
    }
    return '${gain.toStringAsFixed(0)}m';
  }

  factory RouteInfo.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry']?['coordinates'] as List? ?? [];
    final coordinates = <Map<String, double>>[];

    for (final coord in geometry) {
      if (coord is List && coord.length >= 2) {
        coordinates.add({
          'lat': coord[1] as double,
          'lon': coord[0] as double,
        });
      }
    }

    return RouteInfo(
      coordinates: coordinates,
      distanceMeters: (json['distance'] as num?)?.toDouble() ?? 0,
      durationSeconds: (json['duration'] as num?)?.toDouble() ?? 0,
    );
  }
}
