import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/location.dart';

class GeocodingService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';

  static Future<List<Location>> searchLocations(String query) async {
    if (query.isEmpty) return [];

    try {
      final url = '$_baseUrl/search?q=$query&format=json&limit=5';
      print('🔍 Searching: $query');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'TerrainIQ-App'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final results = jsonDecode(response.body) as List;
        final locations = results
            .map((r) => Location.fromJson(r as Map<String, dynamic>))
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
