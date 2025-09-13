import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GeofenceManagerView extends StatefulWidget {
  const GeofenceManagerView({super.key});

  @override
  State<GeofenceManagerView> createState() => _GeofenceManagerViewState();
}

class _GeofenceManagerViewState extends State<GeofenceManagerView> {
  final _nameController = TextEditingController();

  List<Polygon<Object>> _geofences = [];
  List<LatLng> _newPolygonPoints = [];
  bool _isDrawingMode = false;
  bool _isLoading = false;

  final String _backendUrl = 'http://127.0.0.1:5000';

  @override
  void initState() {
    super.initState();
    _fetchGeofences();
  }

  Future<void> _fetchGeofences() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('$_backendUrl/geofences'));
      if (mounted && response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Polygon<Object>> polygons = data.map((fence) {
          final List<dynamic> pointsData = fence['area'];
          final List<LatLng> points = pointsData.map((p) => LatLng(p[0], p[1])).toList();
          return Polygon<Object>(
            points: points,
            color: Colors.green.withOpacity(0.4),
            borderColor: Colors.green,
            borderStrokeWidth: 2,
          );
        }).toList();
        setState(() => _geofences = polygons);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not fetch geofences: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveGeofence() async {
    if (_newPolygonPoints.length < 3 || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('A geofence requires a name and at least 3 points.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final body = json.encode({
        'name': _nameController.text,
        'area': _newPolygonPoints.map((p) => [p.latitude, p.longitude]).toList(),
      });
      final response = await http.post(Uri.parse('$_backendUrl/geofences'),
          headers: {'Content-Type': 'application/json'}, body: body);

      if (mounted && response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geofence saved!'), backgroundColor: Colors.green),
        );
        _toggleDrawingMode();
        _fetchGeofences();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving geofence: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleMapTap(TapPosition? tapPosition, LatLng latlng) {
    if (_isDrawingMode) {
      setState(() => _newPolygonPoints.add(latlng));
    }
  }

  void _toggleDrawingMode() {
    setState(() {
      // FIXED: Corrected the variable name from _isDrawing to _isDrawingMode
      _isDrawingMode = !_isDrawingMode;
      _newPolygonPoints.clear();
      _nameController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // THEME: Set a transparent background so the color from the parent Scaffold shows through
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(17.3850, 78.4867),
              initialZoom: 12.0,
              onTap: _handleMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              PolygonLayer(polygons: [
                ..._geofences,
                if (_newPolygonPoints.isNotEmpty)
                  Polygon<Object>(
                    points: _newPolygonPoints,
                    color: Colors.blue.withOpacity(0.5),
                    borderColor: Colors.blue,
                    borderStrokeWidth: 3,
                  )
              ]),
              if (_newPolygonPoints.isNotEmpty)
                MarkerLayer(
                  markers: _newPolygonPoints.map((point) => Marker(
                        point: point,
                        child: const Icon(Icons.circle, color: Colors.blue, size: 12),
                      )).toList(),
                ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
          if (_isDrawingMode) _buildDrawingControls(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleDrawingMode,
        backgroundColor: _isDrawingMode ? Colors.red : Theme.of(context).primaryColor,
        icon: Icon(_isDrawingMode ? Icons.close : Icons.add_location_alt),
        label: Text(_isDrawingMode ? 'Cancel' : 'Create Geofence'),
      ),
    );
  }

  Widget _buildDrawingControls() {
    return Positioned(
      bottom: 80,
      left: 16,
      right: 16,
      child: Card(
        // THEME: Style the card to match the dark theme
        color: const Color(0xFF2d3748),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Drawing Mode', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white), // THEME: Text color for input
                decoration: InputDecoration(
                  labelText: 'Geofence Name',
                  // THEME: Style the input field for the dark theme
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade600)
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent)
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => setState(() => _newPolygonPoints.clear()),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  ),
                  ElevatedButton.icon(
                    onPressed: _saveGeofence,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Zone'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}