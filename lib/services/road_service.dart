import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RoadService {
  static const String _baseUrl = 'https://overpass-api.de/api/interpreter';
  static const double _cacheRadius = 0.02; // Smaller = faster, only 2km radius

  // Cache roads by location
  static final Map<String, List<Polyline>> _roadCache = {};
  static LatLng? _lastFetchedCenter;

  static bool _shouldRefetch(LatLng center) {
    if (_lastFetchedCenter == null) return true;
    
    final latDiff = (center.latitude - _lastFetchedCenter!.latitude).abs();
    final lonDiff = (center.longitude - _lastFetchedCenter!.longitude).abs();
    return latDiff > _cacheRadius || lonDiff > _cacheRadius;
  }

  static String _getCacheKey(LatLng center) {
    return '${(center.latitude / _cacheRadius).toStringAsFixed(0)}_'
        '${(center.longitude / _cacheRadius).toStringAsFixed(0)}';
  }

  static Color _getColorForSurface(String surface) {
    switch (surface) {
      case 'tar':
        return Colors.green;
      case 'gravel':
        return const Color(0xFFD4A574);
      default:
        return Colors.grey;
    }
  }

  static String _parseSurface(String surface) {
    surface = surface.toLowerCase();
    if (surface.contains('asphalt') ||
        surface.contains('concrete') ||
        surface.contains('paved')) {
      return 'tar';
    } else if (surface.contains('gravel') ||
        surface.contains('dirt') ||
        surface.contains('unpaved')) {
      return 'gravel';
    }
    return 'unknown';
  }

  static Future<List<Polyline>> fetchRoads(LatLng center) async {
    // Check cache first
    final cacheKey = _getCacheKey(center);
    if (_roadCache.containsKey(cacheKey)) {
      print('✓ Using cached roads for $cacheKey');
      return _roadCache[cacheKey]!;
    }

    // Check if we should refetch (user moved > 4km)
    if (!_shouldRefetch(center)) {
      final existingKey = _roadCache.keys.firstWhere(
        (key) => _roadCache[key] != null,
        orElse: () => '',
      );
      if (existingKey.isNotEmpty) {
        print('✓ Using nearby cached roads from $existingKey');
        return _roadCache[existingKey]!;
      }
    }

    try {
      final lat = center.latitude;
      final lon = center.longitude;
      final south = lat - _cacheRadius;
      final west = lon - _cacheRadius;
      final north = lat + _cacheRadius;
      final east = lon + _cacheRadius;

      // Query ONLY primary roads with 8 second timeout
      final queryString = '[out:json][timeout:8];'
          '(way[highway=primary]'
          '($south,$west,$north,$east););'
          'out geom;';

      print('📡 Fetching primary roads for: $lat, $lon');
      final response = await http.post(
        Uri.parse(_baseUrl),
        body: queryString,
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final ways = data['elements'] as List? ?? [];

          final polylines = <Polyline>[];
          int roadCount = 0;
          
          // Limit to 50 roads max for performance
          for (final way in ways) {
            if (roadCount >= 50) break;
            if (way['type'] != 'way') continue;

            final geometry = way['geometry'] as List? ?? [];
            if (geometry.length < 2) continue;

            final tags = way['tags'] as Map<String, dynamic>? ?? {};
            final surface = tags['surface'] as String? ?? 'unknown';

            // Parse surface type and get color
            final surfaceType = _parseSurface(surface);
            final color = _getColorForSurface(surfaceType);

            final latLngs = <LatLng>[];
            for (final point in geometry) {
              if (point is Map && point['lat'] != null && point['lon'] != null) {
                latLngs.add(LatLng(point['lat'], point['lon']));
              }
            }

            if (latLngs.length >= 2) {
              polylines.add(
                Polyline(
                  points: latLngs,
                  color: color,
                  strokeWidth: 2.5,
                  borderColor: color.withValues(alpha: 0.5),
                  borderStrokeWidth: 0.5,
                ),
              );
              roadCount++;
            }
          }

          // Cache the result
          _roadCache[cacheKey] = polylines;
          _lastFetchedCenter = center;
          print('✓ Loaded $roadCount primary roads');

          return polylines;
        } catch (e) {
          print('❌ Parse error: $e');
          // Return empty - will show sample roads
        }
      } else {
        print('❌ HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Road fetch error: $e');
    }

    // Return empty polylines - UI will show map without roads
    print('ℹ️ No roads available, showing blank map');
    return [];
  }
}
