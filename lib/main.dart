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
  final fromSearchController = TextEditingController();
  final toSearchController = TextEditingController();
  LatLng currentLocation = const LatLng(-26.2041, 28.0473); // Johannesburg
  LatLng? destinationLocation;
  bool isSearching = false;
  List<Map<String, dynamic>> suggestions = [];
  bool showSuggestions = false;
  List<Polyline> roadPolylines = [];
  bool isLoadingRoads = false;
  Polyline? routePolyline;
  bool isCalculatingRoute = false;
  String routeInfo = '';
  bool isEditingTo = false; // Track which field is being edited

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    fromSearchController.addListener(_onFromSearchChanged);
    toSearchController.addListener(_onToSearchChanged);
    _fetchRoads(currentLocation);
  }

  @override
  void dispose() {
    fromSearchController.removeListener(_onFromSearchChanged);
    toSearchController.removeListener(_onToSearchChanged);
    fromSearchController.dispose();
    toSearchController.dispose();
    super.dispose();
  }

  void _onFromSearchChanged() {
    setState(() => isEditingTo = false);
    if (fromSearchController.text.isEmpty) {
      setState(() {
        suggestions = [];
        showSuggestions = false;
      });
      return;
    }
    _fetchSuggestions(fromSearchController.text);
  }

  void _onToSearchChanged() {
    setState(() => isEditingTo = true);
    if (toSearchController.text.isEmpty) {
      setState(() {
        suggestions = [];
        showSuggestions = false;
      });
      return;
    }
    _fetchSuggestions(toSearchController.text);
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

  Future<void> selectFromLocation(Map<String, dynamic> location) async {
    final lat = location['lat'] as double;
    final lon = location['lon'] as double;
    final newLocation = LatLng(lat, lon);

    setState(() {
      currentLocation = newLocation;
      fromSearchController.text = location['display_name'];
      suggestions = [];
      showSuggestions = false;
    });

    mapController.move(newLocation, 14);
    _fetchRoads(newLocation);

    // If destination exists, calculate route
    if (destinationLocation != null) {
      _calculateRoute(newLocation, destinationLocation!);
    }
  }

  Future<void> selectToLocation(Map<String, dynamic> location) async {
    final lat = location['lat'] as double;
    final lon = location['lon'] as double;
    final newLocation = LatLng(lat, lon);

    setState(() {
      destinationLocation = newLocation;
      toSearchController.text = location['display_name'];
      suggestions = [];
      showSuggestions = false;
    });

    // Calculate route from current to destination
    _calculateRoute(currentLocation, newLocation);
  }

  Future<void> _calculateRoute(LatLng start, LatLng end) async {
    setState(() => isCalculatingRoute = true);

    try {
      // Use OSRM (Open Source Routing Machine) - free routing service
      final url = 'https://router.project-osrm.org/route/v1/driving/'
          '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
          '?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final routes = data['routes'] as List?;

        if (routes != null && routes.isNotEmpty) {
          final route = routes[0];
          final geometry = route['geometry']['coordinates'] as List;
          final distance = route['distance'] as num; // meters
          final duration = route['duration'] as num; // seconds

          // Convert to LatLng
          final routePoints = <LatLng>[];
          for (final coord in geometry) {
            routePoints.add(LatLng(coord[1], coord[0]));
          }

          // Format info
          final distanceKm = (distance / 1000).toStringAsFixed(1);
          final durationMin = (duration / 60).toStringAsFixed(0);

          setState(() {
            routePolyline = Polyline(
              points: routePoints,
              color: Colors.blue,
              strokeWidth: 4,
              borderColor: Colors.blue.shade900,
              borderStrokeWidth: 1,
            );
            routeInfo = '$distanceKm km • $durationMin min';
          });

          debugPrint('✓ Route: $distanceKm km, $durationMin minutes');
        }
      }
    } catch (e) {
      debugPrint('Route calculation error: $e');
    } finally {
      setState(() => isCalculatingRoute = false);
    }
  }

  Future<void> _fetchRoads(LatLng center) async {
    setState(() => isLoadingRoads = true);

    try {
      // Build Overpass API request
      final lat = center.latitude;
      final lon = center.longitude;
      final south = lat - 0.04;
      final west = lon - 0.04;
      final north = lat + 0.04;
      final east = lon + 0.04;
      
      final queryString = '[out:json];'
          '(way[highway~"^(primary|secondary|tertiary|residential|living_street)\$"][surface]'
          '($south,$west,$north,$east););'
          'out body geom;';

      final url = 'https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(queryString)}';

      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final ways = data['elements'] as List? ?? [];
          
          if (ways.isNotEmpty) {
            final roads = _parseRealRoads(ways);
            setState(() => roadPolylines = roads);
            debugPrint('✓ Loaded ${roads.length} road segments');
          } else {
            debugPrint('No ways found - using sample roads');
            final sampleRoads = _generateSampleRoads(center);
            setState(() => roadPolylines = sampleRoads);
          }
        } catch (e) {
          debugPrint('Parse error: $e - using sample roads');
          final sampleRoads = _generateSampleRoads(center);
          setState(() => roadPolylines = sampleRoads);
        }
      } else {
        debugPrint('HTTP ${response.statusCode} - using sample roads');
        final sampleRoads = _generateSampleRoads(center);
        setState(() => roadPolylines = sampleRoads);
      }
    } catch (e) {
      debugPrint('Request failed: $e - using sample roads');
      final sampleRoads = _generateSampleRoads(center);
      setState(() => roadPolylines = sampleRoads);
    } finally {
      setState(() => isLoadingRoads = false);
    }
  }

  List<Polyline> _parseRealRoads(List<dynamic> ways) {
    final polylines = <Polyline>[];
    
    for (final way in ways) {
      if (way['type'] != 'way') continue;

      final tags = way['tags'] as Map<String, dynamic>? ?? {};
      final geometry = way['geometry'] as List? ?? [];

      if (geometry.isEmpty) continue;

      final surface = (tags['surface'] as String? ?? 'unknown').toLowerCase();

      // Determine color based on surface
      Color roadColor;
      if (surface.contains('asphalt') || 
          surface.contains('concrete') || 
          surface.contains('paved') ||
          surface == 'smooth') {
        roadColor = Colors.green; // Tar/Asphalt
      } else if (surface.contains('gravel') || 
                 surface.contains('dirt') || 
                 surface.contains('unpaved') ||
                 surface.contains('ground')) {
        roadColor = const Color(0xFFD4A574); // Gravel/brown
      } else {
        roadColor = Colors.grey; // Unknown
      }

      // Convert geometry to LatLng points
      final latLngs = <LatLng>[];
      for (final point in geometry) {
        if (point is Map) {
          final lat = point['lat'];
          final lon = point['lon'];
          if (lat != null && lon != null) {
            latLngs.add(LatLng(lat, lon));
          }
        }
      }

      if (latLngs.isNotEmpty) {
        polylines.add(
          Polyline(
            points: latLngs,
            color: roadColor,
            strokeWidth: 2.5,
            borderColor: roadColor.withOpacity(0.5),
            borderStrokeWidth: 0.5,
          ),
        );
      }
    }

    return polylines;
  }

  List<Polyline> _generateSampleRoads(LatLng center) {
    final polylines = <Polyline>[];
    
    // Sample tar roads (green)
    polylines.add(Polyline(
      points: [
        LatLng(center.latitude - 0.02, center.longitude - 0.02),
        LatLng(center.latitude, center.longitude - 0.01),
        LatLng(center.latitude + 0.02, center.longitude),
      ],
      color: Colors.green,
      strokeWidth: 2.5,
    ));

    polylines.add(Polyline(
      points: [
        LatLng(center.latitude - 0.01, center.longitude - 0.03),
        LatLng(center.latitude - 0.01, center.longitude + 0.03),
      ],
      color: Colors.green,
      strokeWidth: 2.5,
    ));

    // Sample gravel roads (brown)
    polylines.add(Polyline(
      points: [
        LatLng(center.latitude + 0.01, center.longitude - 0.02),
        LatLng(center.latitude + 0.03, center.longitude - 0.01),
        LatLng(center.latitude + 0.03, center.longitude + 0.02),
      ],
      color: const Color(0xFFD4A574),
      strokeWidth: 2.5,
    ));

    polylines.add(Polyline(
      points: [
        LatLng(center.latitude, center.longitude + 0.02),
        LatLng(center.latitude + 0.02, center.longitude + 0.03),
      ],
      color: const Color(0xFFD4A574),
      strokeWidth: 2.5,
    ));

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
              // Route polyline
              if (routePolyline != null)
                PolylineLayer(
                  polylines: [routePolyline!],
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
                  // Destination marker
                  if (destinationLocation != null)
                    Marker(
                      point: destinationLocation!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 20,
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
                // From location search
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
                    controller: fromSearchController,
                    decoration: InputDecoration(
                      hintText: 'From...',
                      hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                      prefixIcon: Icon(Icons.location_on, color: Colors.blue.shade300),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: fromSearchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                fromSearchController.clear();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // To location search
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
                    controller: toSearchController,
                    decoration: InputDecoration(
                      hintText: 'To...',
                      hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                      prefixIcon: Icon(Icons.location_on, color: Colors.red.shade300),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: toSearchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                toSearchController.clear();
                                setState(() {
                                  destinationLocation = null;
                                  routePolyline = null;
                                  routeInfo = '';
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
                          onTap: () {
                            if (isEditingTo) {
                              selectToLocation(suggestion);
                            } else {
                              selectFromLocation(suggestion);
                            }
                          },
                          hoverColor: Colors.blue.withOpacity(0.1),
                        );
                      },
                    ),
                  ),
                // Route info
                if (routeInfo.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2634),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.directions, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            routeInfo,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isCalculatingRoute)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.blue),
                            ),
                          ),
                      ],
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
