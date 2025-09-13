import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:sih_proto/providers/app_state.dart';
import 'package:sih_proto/utils/app_theme.dart';
import 'package:http/http.dart' as http;

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  List<Polygon<Object>> _geofences = [];
  bool _isLoadingFences = true;

  // FIXED: Changed URL for web/desktop compatibility.
  final String _backendUrl = 'http://127.0.0.1:5000';

  @override
  void initState() {
    super.initState();
    _fetchGeofences();
  }

  Future<void> _fetchGeofences() async {
    try {
      final response = await http.get(Uri.parse('$_backendUrl/geofences'));
      if (mounted) {
        if (response.statusCode == 200) {
            final List<dynamic> data = json.decode(response.body);
            final List<Polygon<Object>> polygons = data.map((fence) {
              final List<dynamic> pointsData = fence['area'];
              final List<LatLng> points = pointsData
                  .map((p) => LatLng(p[0].toDouble(), p[1].toDouble()))
                  .toList();
              return Polygon<Object>(
                  points: points,
                  color: Colors.orange.withOpacity(0.4),
                  borderColor: Colors.orange,
                  borderStrokeWidth: 2,
              );
            }).toList();

            setState(() {
              _geofences = polygons;
            });
        } else {
            throw Exception('Failed to load geofences');
        }
      }
    } catch (e) {
      debugPrint("Error fetching geofences: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not load safe zones: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
            _isLoadingFences = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Map')),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          final initialPosition = appState.currentPosition;

          if (initialPosition == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.accentColor),
                  SizedBox(height: 16),
                  Text("Fetching your location..."),
                ],
              ),
            );
          }

          final userLocation = LatLng(initialPosition.latitude, initialPosition.longitude);

          return FlutterMap(
            options: MapOptions(
              initialCenter: userLocation,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                // REMOVED: subdomains property to resolve map warning
              ),
              if (!_isLoadingFences) PolygonLayer(polygons: _geofences),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 100.0,
                    height: 100.0,
                    point: userLocation,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text("YOU", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                        const Icon(Icons.arrow_drop_down, color: AppTheme.accentColor, size: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}