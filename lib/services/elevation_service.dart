import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';

class ElevationService {
  static const String _baseUrl = 'https://api.open-elevation.com/api/v1/lookup';

  static Future<List<double>> getElevations(List<Map<String, double>> coordinates) async {
    if (coordinates.isEmpty) return [];

    try {
      // Build location array
      final locations = coordinates
          .map((c) => {'latitude': c['lat'], 'longitude': c['lon']})
          .toList();

      final url = Uri.parse(_baseUrl);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'locations': locations}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List?;

        if (results != null && results.isNotEmpty) {
          final elevations = (results as List)
              .map((r) => (r['elevation'] as num?)?.toDouble() ?? 0.0)
              .toList();

          print('✓ Retrieved ${elevations.length} elevation points');
          return elevations;
        }
      }
    } catch (e) {
      print('⚠️ Elevation API error: $e');
    }

    return [];
  }

  // Calculate gradient percentage between two elevation points and distance
  static double calculateGradient(double elev1, double elev2, double distanceMeters) {
    if (distanceMeters == 0) return 0;
    final elevChange = (elev2 - elev1).abs();
    return (elevChange / distanceMeters) * 100; // percentage
  }

  // Classify gradient severity
  static String classifyGradient(double gradientPercent) {
    if (gradientPercent < 3) return 'flat'; // 🟢
    if (gradientPercent < 8) return 'moderate'; // 🟡
    return 'steep'; // 🔴
  }

  // Get color for gradient
  static int getGradientColor(double gradientPercent) {
    if (gradientPercent < 3) return 0xFF2ecc71; // Green - flat
    if (gradientPercent < 8) return 0xFFf39c12; // Orange - moderate
    return 0xFFe74c3c; // Red - steep
  }
}
