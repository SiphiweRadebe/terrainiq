import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/location.dart';

class GeocodingService {
  static const String _baseUrl = 'https://photon.komoot.io';

  static Future<List<Location>> searchLocations(String query) async {
    if (query.isEmpty) return [];

    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = '$_baseUrl/api?q=$encodedQuery&limit=10&lang=en';
      print('🔍 Searching: $query');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'TerrainIQ-App'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List? ?? [];
        final locations = features
            .map((f) => Location.fromPhoton(f as Map<String, dynamic>))
            .toList();
        print('✓ Found ${locations.length} locations');
        return locations;
      } else {
        print('❌ Geocoding HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Geocoding error: $e');
    }
    return [];
  }
}
