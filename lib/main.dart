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

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    searchController.addListener(_onSearchChanged);
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Found: ${location['display_name']}'),
        duration: const Duration(seconds: 2),
      ),
    );
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
}
