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

  factory Location.fromPhoton(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>? ?? {};
    final coords = json['geometry']?['coordinates'] as List? ?? [0, 0];
    
    // Build display name from available properties
    final parts = <String>[];
    if (props['street'] != null) parts.add(props['street'] as String);
    if (props['name'] != null && props['name'] != props['street']) parts.add(props['name'] as String);
    if (props['city'] != null) parts.add(props['city'] as String);
    if (props['state'] != null) parts.add(props['state'] as String);
    if (props['country'] != null) parts.add(props['country'] as String);
    
    final displayName = parts.join(', ');
    
    return Location(
      displayName: displayName.isNotEmpty ? displayName : 'Unknown Location',
      latitude: (coords[1] as num).toDouble(),
      longitude: (coords[0] as num).toDouble(),
    );
  }

  @override
  String toString() => '$displayName ($latitude, $longitude)';
}
