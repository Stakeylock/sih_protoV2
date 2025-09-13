import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sih_proto/services/supabase_config.dart';

class SafetyZoneManager extends StatefulWidget {
  const SafetyZoneManager({super.key});

  @override
  State<SafetyZoneManager> createState() => _SafetyZoneManagerState();
}

class _SafetyZoneManagerState extends State<SafetyZoneManager> {
  final SupabaseManager _supabaseManager = SupabaseManager();
  final _nameController = TextEditingController();

  List<SafetyZone> _zones = [];
  List<LatLng> _newPolygonPoints = [];
  bool _isDrawingMode = false;
  String _selectedZoneType = 'green'; // Default to green

  @override
  void initState() {
    super.initState();
    _fetchSafetyZones();
  }

  Future<void> _fetchSafetyZones() async {
    final zones = await _supabaseManager.getSafetyZones();
    if (mounted) {
      setState(() => _zones = zones);
    }
  }

  void _handleMapTap(TapPosition? tapPosition, LatLng latlng) {
    if (_isDrawingMode) {
      setState(() => _newPolygonPoints.add(latlng));
    }
  }

  void _toggleDrawingMode() {
    setState(() {
      _isDrawingMode = !_isDrawingMode;
      _newPolygonPoints.clear();
      _nameController.clear();
      _selectedZoneType = 'green';
    });
  }

  Future<void> _saveNewZone() async {
    if (_newPolygonPoints.length < 3 || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('A zone requires a name and at least 3 points.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    try {
      await _supabaseManager.addSafetyZone(
        name: _nameController.text,
        area: _newPolygonPoints,
        zoneType: _selectedZoneType,
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('New safety zone saved!'),
        backgroundColor: Colors.green,
      ));
      _toggleDrawingMode();
      _fetchSafetyZones(); // Refresh the map
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error saving zone: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }
  
  Color _getColorForZone(String zoneType, {bool isBorder = false}) {
    switch (zoneType) {
      case 'red':
        return isBorder ? Colors.red.shade800 : Colors.red.withOpacity(0.5);
      case 'orange':
        return isBorder ? Colors.orange.shade800 : Colors.orange.withOpacity(0.5);
      case 'green':
      default:
        return isBorder ? Colors.green.shade800 : Colors.green.withOpacity(0.5);
    }
  }
  
  Polygon _buildPolygonForZone(SafetyZone zone) {
    return Polygon(
      points: zone.area,
      color: _getColorForZone(zone.zoneType),
      borderColor: _getColorForZone(zone.zoneType, isBorder: true),
      borderStrokeWidth: 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a202c),
      appBar: AppBar(
        title: const Text('Safety Zone Manager'),
        backgroundColor: const Color(0xFF2d3748),
      ),
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
              PolygonLayer(
                polygons: [
                  ..._zones.map((zone) => _buildPolygonForZone(zone)),
                  if (_newPolygonPoints.isNotEmpty)
                    Polygon(
                      points: _newPolygonPoints,
                      color: Colors.blue.withOpacity(0.4),
                      borderColor: Colors.blueAccent,
                      borderStrokeWidth: 3,
                      // FIXED: Removed the unsupported 'isDotted' parameter
                    ),
                ],
              ),
              if (_newPolygonPoints.isNotEmpty)
                MarkerLayer(
                  markers: _newPolygonPoints
                      .map((p) => Marker(
                            point: p,
                            child: const Icon(Icons.circle, color: Colors.blueAccent, size: 10),
                          ))
                      .toList(),
                ),
            ],
          ),
          if (_isDrawingMode) _buildDrawingControls(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleDrawingMode,
        backgroundColor: _isDrawingMode ? Colors.red : Theme.of(context).primaryColor,
        icon: Icon(_isDrawingMode ? Icons.close : Icons.add_location_alt_rounded),
        label: Text(_isDrawingMode ? 'Cancel' : 'Create Zone'),
      ),
    );
  }

  Widget _buildDrawingControls() {
    return Positioned(
      bottom: 80,
      left: 16,
      right: 16,
      child: Card(
        color: const Color(0xFF2d3748),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Create New Safety Zone', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Zone Name',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1a202c),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedZoneType,
                dropdownColor: const Color(0xFF2d3748),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Zone Type',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1a202c),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: ['green', 'orange', 'red']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedZoneType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => setState(() => _newPolygonPoints.clear()),
                    icon: const Icon(Icons.delete_sweep_rounded),
                    label: const Text('Clear Points'),
                    style: TextButton.styleFrom(foregroundColor: Colors.orangeAccent),
                  ),
                  ElevatedButton.icon(
                    onPressed: _saveNewZone,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Save Zone'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

