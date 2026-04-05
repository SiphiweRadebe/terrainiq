import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/location.dart';
import '../models/route.dart' as route_model;
import '../services/geocoding_service.dart';
import '../services/routing_service.dart';
import '../services/road_service.dart';
import '../utils/constants.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _fromSearchController = TextEditingController();
  final TextEditingController _toSearchController = TextEditingController();

  // Location state
  LatLng _currentLocation = const LatLng(-26.2041, 28.0473); // Johannesburg
  LatLng? _destinationLocation;

  // Search state
  List<Location> _suggestions = [];
  bool _showSuggestions = false;
  bool _isEditingTo = false;

  // Route state
  Polyline? _routePolyline;
  route_model.RouteInfo? _currentRoute;
  bool _isCalculatingRoute = false;

  // Road state
  List<Polyline> _roadPolylines = [];

  // Performance optimizations
  Timer? _searchDebounceTimer;
  Timer? _roadDebounceTimer;

  @override
  void initState() {
    super.initState();
    _fromSearchController.addListener(_onFromSearchChanged);
    _toSearchController.addListener(_onToSearchChanged);
    // Start fetching roads from initial location
    _fetchRoads(_currentLocation);
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _roadDebounceTimer?.cancel();
    _fromSearchController.dispose();
    _toSearchController.dispose();
    super.dispose();
  }

  void _onFromSearchChanged() {
    setState(() => _isEditingTo = false);
    _searchDebounceTimer?.cancel();

    if (_fromSearchController.text.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    _searchDebounceTimer = Timer(
      const Duration(milliseconds: searchDebounceMs),
      () => _fetchSuggestions(_fromSearchController.text),
    );
  }

  void _onToSearchChanged() {
    setState(() => _isEditingTo = true);
    _searchDebounceTimer?.cancel();

    if (_toSearchController.text.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    _searchDebounceTimer = Timer(
      const Duration(milliseconds: searchDebounceMs),
      () => _fetchSuggestions(_toSearchController.text),
    );
  }

  Future<void> _fetchSuggestions(String query) async {
    final results = await GeocodingService.searchLocations(query);
    setState(() {
      _suggestions = results;
      _showSuggestions = true;
    });
  }

  Future<void> _selectFromLocation(Location location) async {
    setState(() {
      _currentLocation = LatLng(location.latitude, location.longitude);
      _fromSearchController.text = location.displayName;
      _suggestions = [];
      _showSuggestions = false;
    });

    _mapController.move(_currentLocation, 13);
    _fetchRoads(_currentLocation);

    if (_destinationLocation != null) {
      _calculateRoute(_currentLocation, _destinationLocation!);
    }
  }

  Future<void> _selectToLocation(Location location) async {
    setState(() {
      _destinationLocation = LatLng(location.latitude, location.longitude);
      _toSearchController.text = location.displayName;
      _suggestions = [];
      _showSuggestions = false;
    });

    _mapController.move(_destinationLocation!, 13);
    _fetchRoads(_destinationLocation!);

    _calculateRoute(_currentLocation, _destinationLocation!);
  }

  Future<void> _calculateRoute(LatLng start, LatLng end) async {
    setState(() => _isCalculatingRoute = true);

    final route = await RoutingService.calculateRoute(start, end);

    setState(() {
      _isCalculatingRoute = false;
      if (route != null) {
        _currentRoute = route;
        _routePolyline = Polyline(
          points: route.coordinates
              .map((c) => LatLng(c['lat']!, c['lon']!))
              .toList(),
          color: Colors.blue,
          strokeWidth: 4,
        );
      }
    });
  }

  void _fetchRoads(LatLng center) {
    _roadDebounceTimer?.cancel();
    _roadDebounceTimer = Timer(
      const Duration(milliseconds: roadDebounceMs),
      () async {
        final roads = await RoadService.fetchRoads(center);
        setState(() => _roadPolylines = roads);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 12,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com/terrainiq',
              ),
             
PolylineLayer(polylines: [
                ..._roadPolylines,
                if (_routePolyline != null) _routePolyline!,
              ]),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.blue,
                      size: 40,
                    ),
                  ),
                  if (_destinationLocation != null)
                    Marker(
                      point: _destinationLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Search Bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2332),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[700]!),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _fromSearchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'From',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          prefixIcon:
                              Icon(Icons.location_on, color: Colors.blue[300]),
                        ),
                      ),
                      Divider(
                        color: Colors.grey[700],
                        height: 1,
                        thickness: 0.5,
                      ),
                      TextField(
                        controller: _toSearchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'To',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          prefixIcon: Icon(Icons.flag, color: Colors.red[300]),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_showSuggestions && _suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2332),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[700]!),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey[700]),
                      itemBuilder: (_, index) {
                        final location = _suggestions[index];
                        return ListTile(
                          title: Text(
                            location.displayName,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            if (_isEditingTo) {
                              _selectToLocation(location);
                            } else {
                              _selectFromLocation(location);
                            }
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Route Info
          if (_currentRoute != null && !_isCalculatingRoute)
            Positioned(
              top: 200,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2332),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Text(
                  _currentRoute!.displayInfo,
                  style: TextStyle(
                    color: Colors.green[300],
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Legend
          Positioned(
            bottom: 24,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2332),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _legendItem(Colors.green, 'Paved'),
                  const SizedBox(height: 8),
                  _legendItem(const Color(0xFFD4A574), 'Gravel'),
                  const SizedBox(height: 8),
                  _legendItem(Colors.grey, 'Unknown'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
      ],
    );
  }
}
