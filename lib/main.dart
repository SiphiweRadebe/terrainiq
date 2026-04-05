import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const TerrainIQApp());
}

class TerrainIQApp extends StatelessWidget {
  const TerrainIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TerrainIQ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F1923),
      ),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late MapController mapController;
  final searchController = TextEditingController();
  LatLng currentLocation = const LatLng(-26.2041, 28.0473); // Johannesburg
  bool isSearching = false;
  List<Map<String, dynamic>> suggestions = [];
  bool showSuggestions = false;
  List<Polyline> roadPolylines = [];
  bool isLoadingRoads = false;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    searchController.addListener(_onSearchChanged);
    _fetchRoads(currentLocation);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (searchController.text.isEmpty) {
      setState(() {
        suggestions = [];
        showSuggestions = false;
      });
      return;
    }
    _fetchSuggestions(searchController.text);
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5',
        ),
        headers: {
          'User-Agent': 'TerrainIQ-App',
        },
      );

      if (response.statusCode == 200) {
        final results = jsonDecode(response.body) as List;
        setState(() {
          suggestions = results
              .map((r) => {
                    'display_name': r['display_name'] as String,
                    'lat': double.parse(r['lat']),
                    'lon': double.parse(r['lon']),
                  })
              .toList();
          showSuggestions = suggestions.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
    }
  }

  Future<void> selectLocation(Map<String, dynamic> location) async {
    final lat = location['lat'] as double;
    final lon = location['lon'] as double;
    final newLocation = LatLng(lat, lon);

    setState(() {
      currentLocation = newLocation;
      searchController.text = location['display_name'];
      suggestions = [];
      showSuggestions = false;
    });

    mapController.move(newLocation, 14);
    _fetchRoads(newLocation);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Found: ${location['display_name']}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _fetchRoads(LatLng center) async {
    setState(() => isLoadingRoads = true);

    try {
      // Use Overpass API to get roads with surface information
      final bbox = '${center.latitude - 0.05},${center.longitude - 0.05},${center.latitude + 0.05},${center.longitude + 0.05}';
      final query = '''
        [bbox:$bbox][out:json];
        (
          way[highway][surface];
        );
        out center;
      ''';

      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: query,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final roads = _parseRoads(data);
        setState(() => roadPolylines = roads);
      }
    } catch (e) {
      debugPrint('Error fetching roads: $e');
    } finally {
      setState(() => isLoadingRoads = false);
    }
  }

  List<Polyline> _parseRoads(Map<String, dynamic> data) {
    final polylines = <Polyline>[];
    final ways = data['elements'] as List? ?? [];
    final nodes = <int, List<double>>{};

    // Build node map
    for (final element in ways) {
      if (element['type'] == 'node') {
        nodes[element['id']] = [element['lat'], element['lon']];
      }
    }

    // Build polylines from ways
    for (final way in ways) {
      if (way['type'] != 'way') continue;

      final tags = way['tags'] as Map<String, dynamic>? ?? {};
      final surface = (tags['surface'] as String? ?? 'unknown').toLowerCase();
      final roadType = (tags['highway'] as String? ?? 'road').toLowerCase();

      // Skip insignificant roads
      if (['footway', 'path', 'track', 'service'].contains(roadType)) continue;

      // Determine color based on surface
      Color roadColor;
      if (surface.contains('asphalt') || surface.contains('concrete') || surface == 'paved_smooth') {
        roadColor = Colors.green; // Tar/Asphalt
      } else if (surface.contains('gravel') || surface.contains('dirt') || surface.contains('unpaved')) {
        roadColor = const Color(0xFFD4A574); // Gravel/brown
      } else {
        roadColor = Colors.grey; // Unknown
      }

      final nodeIds = way['nodes'] as List? ?? [];
      final latLngs = <LatLng>[];

      for (final nodeId in nodeIds) {
        if (nodes.containsKey(nodeId)) {
          final coord = nodes[nodeId]!;
          latLngs.add(LatLng(coord[0], coord[1]));
        }
      }

      if (latLngs.isNotEmpty) {
        polylines.add(
          Polyline(
            points: latLngs,
            color: roadColor,
            strokeWidth: 3,
            borderColor: roadColor.withOpacity(0.7),
            borderStrokeWidth: 1,
          ),
        );
      }
    }

    return polylines;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: currentLocation,
              initialZoom: 12,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.terrainiq.app',
              ),
              // Road polylines with surface types
              PolylineLayer(
                polylines: roadPolylines,
              ),
              // Current location marker
              MarkerLayer(
                markers: [
                  Marker(
                    point: currentLocation,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Legend
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A2634),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Road Surface',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _legendItem(Colors.green, 'Tar/Asphalt'),
                  _legendItem(const Color(0xFFD4A574), 'Gravel'),
                  _legendItem(Colors.grey, 'Unknown'),
                  if (isLoadingRoads)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.blue),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Search bar with suggestions
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2634),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search location...',
                      hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                searchController.clear();
                                setState(() {
                                  suggestions = [];
                                  showSuggestions = false;
                                });
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                // Suggestions dropdown
                if (showSuggestions && suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2634),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = suggestions[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.location_on,
                            color: Colors.blue,
                            size: 20,
                          ),
                          title: Text(
                            suggestion['display_name'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                          onTap: () => selectLocation(suggestion),
                          hoverColor: Colors.blue.withOpacity(0.1),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
