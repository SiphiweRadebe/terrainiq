import 'package:flutter/material.dart';

enum RoadSurfaceType { tar, gravel, unknown }

class Road {
  final String id;
  final List<Map<String, double>> coordinates;
  final RoadSurfaceType surface;
  final String roadType;
  final Color color;

  Road({
    required this.id,
    required this.coordinates,
    required this.surface,
    required this.roadType,
    required this.color,
  });

  static RoadSurfaceType _parseSurface(String surface) {
    surface = surface.toLowerCase();
    if (surface.contains('asphalt') ||
        surface.contains('concrete') ||
        surface.contains('paved')) {
      return RoadSurfaceType.tar;
    } else if (surface.contains('gravel') ||
        surface.contains('dirt') ||
        surface.contains('unpaved')) {
      return RoadSurfaceType.gravel;
    }
    return RoadSurfaceType.unknown;
  }

  static Color _colorForSurface(RoadSurfaceType surface) {
    switch (surface) {
      case RoadSurfaceType.tar:
        return Colors.green;
      case RoadSurfaceType.gravel:
        return const Color(0xFFD4A574);
      case RoadSurfaceType.unknown:
        return Colors.grey;
    }
  }

  factory Road.fromJson(Map<String, dynamic> json) {
    final tags = json['tags'] as Map<String, dynamic>? ?? {};
    final surface = tags['surface'] as String? ?? 'unknown';
    final roadType = tags['highway'] as String? ?? 'road';
    final geometry = json['geometry'] as List? ?? [];

    final surfaceType = _parseSurface(surface);
    final color = _colorForSurface(surfaceType);

    final coordinates = <Map<String, double>>[];
    for (final point in geometry) {
      if (point is Map) {
        coordinates.add({
          'lat': point['lat'] ?? 0.0,
          'lon': point['lon'] ?? 0.0,
        });
      }
    }

    return Road(
      id: '${json['id']}',
      coordinates: coordinates,
      surface: surfaceType,
      roadType: roadType,
      color: color,
    );
  }
}
