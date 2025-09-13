import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sih_proto/services/supabase_config.dart';

class LiveMonitoringScreen extends StatefulWidget {
  const LiveMonitoringScreen({super.key});

  @override
  State<LiveMonitoringScreen> createState() => _LiveMonitoringScreenState();
}

class _LiveMonitoringScreenState extends State<LiveMonitoringScreen> {
  final SupabaseManager _supabaseManager = SupabaseManager();
  // ADDED: Controller to programmatically move the map
  final MapController _mapController = MapController();

  List<SafetyZone> _safetyZones = [];
  SafetyZone? _selectedZone;
  List<Marker> _touristMarkers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchZones();
  }

  Future<void> _fetchZones() async {
    try {
      final zones = await _supabaseManager.getSafetyZones();
      if (mounted) {
        setState(() {
          _safetyZones = zones;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching zones: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchTouristsInZone(SafetyZone zone) async {
    setState(() {
      _selectedZone = zone;
      _isLoading = true;
      _touristMarkers = [];
    });

    // Safely move the map to the center of the selected zone
    if (zone.area.isNotEmpty) {
      _mapController.move(zone.area.first, 14.0);
    }

    try {
      final tourists = await _supabaseManager.getTouristsInZone(zone.id);
      final markers = tourists.map((tourist) {
        return Marker(
          point: LatLng(tourist['latitude'], tourist['longitude']),
          width: 80,
          height: 80,
          child: Tooltip(
            message: tourist['full_name'] ?? 'Tourist',
            child: const Icon(Icons.person_pin_circle, color: Colors.deepPurple, size: 35),
          ),
        );
      }).toList();

      if (mounted) {
        setState(() {
          _touristMarkers = markers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching tourists: $e'), backgroundColor: Colors.red),
        );
         setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a202c),
      appBar: AppBar(
        title: const Text('Live Tourist Monitoring'),
        backgroundColor: const Color(0xFF2d3748),
      ),
      body: Column(
        children: [
          _buildZoneSelector(),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  // ADDED: Assign the controller to the map
                  mapController: _mapController,
                  options: MapOptions(
                    // A default initial center
                    initialCenter: const LatLng(17.3850, 78.4867),
                    initialZoom: 12.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                    if (_selectedZone != null)
                      PolygonLayer(polygons: [
                        Polygon(
                          points: _selectedZone!.area,
                          color: Colors.blue.withOpacity(0.3),
                          borderColor: Colors.blueAccent,
                          borderStrokeWidth: 2,
                        )
                      ]),
                    MarkerLayer(markers: _touristMarkers),
                  ],
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: const Color(0xFF2d3748),
      child: DropdownButtonFormField<SafetyZone>(
        value: _selectedZone,
        dropdownColor: const Color(0xFF2d3748),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Select a Zone to Monitor',
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFF1a202c),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        hint: const Text('Select a Zone', style: TextStyle(color: Colors.grey)),
        isExpanded: true,
        items: _safetyZones.map((zone) {
          return DropdownMenuItem(
            value: zone,
            child: Text(zone.name),
          );
        }).toList(),
        onChanged: (zone) {
          if (zone != null) {
            _fetchTouristsInZone(zone);
          }
        },
      ),
    );
  }
}

