import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class GeofenceManagerScreen extends StatefulWidget {
  const GeofenceManagerScreen({super.key});

  @override
  State<GeofenceManagerScreen> createState() => _GeofenceManagerScreenState();
}

class _GeofenceManagerScreenState extends State<GeofenceManagerScreen> {
  final List<LatLng> _polygonPoints = [];
  final _nameController = TextEditingController();
  bool _isLoading = false;

  // FIXED: Changed URL for web/desktop compatibility.
  // Use 127.0.0.1 for web/desktop and 10.0.2.2 for Android Emulator.
  final String _backendUrl = 'http://127.0.0.1:5000';

  void _addPoint(LatLng point) {
    setState(() {
      _polygonPoints.add(point);
    });
  }

  void _resetPolygon() {
    setState(() {
      _polygonPoints.clear();
      _nameController.clear();
    });
  }

  Future<void> _saveGeofence() async {
    if (_polygonPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A geofence must have at least 3 points.')),
      );
      return;
    }
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for the geofence.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final body = json.encode({
        'name': _nameController.text,
        'area': _polygonPoints.map((p) => [p.latitude, p.longitude]).toList(),
      });

      final response = await http.post(
        Uri.parse('$_backendUrl/geofences'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (mounted) {
         if (response.statusCode == 201) {
            ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Geofence saved successfully!'), backgroundColor: Colors.green),
            );
            _resetPolygon();
        } else {
            throw Exception('Failed to save geofence: ${response.body}');
        }
      }
    } catch (e) {
        if(mounted){
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
            );
        }
    } finally {
        if(mounted){
            setState(() => _isLoading = false);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geofence Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _resetPolygon,
            tooltip: 'Clear Polygon',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Geofence Name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: const LatLng(17.3020, 78.5277), // Centered on your current location
                initialZoom: 11.0,
                onTap: (_, latlng) => _addPoint(latlng),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  // REMOVED: subdomains property to resolve map warning
                ),
                // FIXED: Only build the PolygonLayer if there are points to draw
                if (_polygonPoints.isNotEmpty)
                  PolygonLayer(
                    polygons: [
                      Polygon<Object>(
                        points: _polygonPoints,
                        color: Colors.blue.withOpacity(0.5),
                        borderColor: Colors.blue,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                if (_polygonPoints.isNotEmpty)
                  MarkerLayer(
                    markers: _polygonPoints.map((point) {
                      return Marker(
                        point: point,
                        width: 10,
                        height: 10,
                        child: const Icon(Icons.circle, color: Colors.red, size: 10),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _saveGeofence,
        label: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Save Geofence'),
        icon: const Icon(Icons.save),
      ),
    );
  }
}