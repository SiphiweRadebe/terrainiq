class RouteInfo {
  final List<Map<String, double>> coordinates;
  final double distanceMeters;
  final double durationSeconds;

  RouteInfo({
    required this.coordinates,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  String get distanceKm => (distanceMeters / 1000).toStringAsFixed(1);
  String get durationMinutes => (durationSeconds / 60).toStringAsFixed(0);
  String get displayInfo => '$distanceKm km • $durationMinutes min';

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
