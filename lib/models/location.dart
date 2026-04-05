class Location {
  final String displayName;
  final double latitude;
  final double longitude;

  Location({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      displayName: json['display_name'] as String,
      latitude: double.parse(json['lat']),
      longitude: double.parse(json['lon']),
    );
  }

  @override
  String toString() => '$displayName ($latitude, $longitude)';
}
