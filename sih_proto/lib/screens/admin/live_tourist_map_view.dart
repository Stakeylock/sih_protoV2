import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sih_proto/services/tourist_location_service.dart';

// Enum for the filter UI
enum FilterType { all, sos, attention }

class LiveTouristMapView extends StatefulWidget {
  const LiveTouristMapView({super.key});

  @override
  State<LiveTouristMapView> createState() => _LiveTouristMapViewState();
}

class _LiveTouristMapViewState extends State<LiveTouristMapView> {
  final TouristLocationService _locationService = TouristLocationService();
  FilterType _activeFilter = FilterType.all;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        StreamBuilder<List<TouristMarker>>(
          stream: _locationService.getTouristLocationsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final allMarkers = snapshot.data ?? [];
            final filteredMarkers = allMarkers.where((marker) {
              switch (_activeFilter) {
                case FilterType.sos:
                  return marker.status == TouristStatus.sos;
                case FilterType.attention:
                  return marker.status == TouristStatus.attention;
                case FilterType.all:
                default:
                  return true;
              }
            }).toList();

            return FlutterMap(
              options: MapOptions(
                initialCenter: const LatLng(17.3850, 78.4867), // Hyderabad
                initialZoom: 12.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                MarkerLayer(
                  markers: filteredMarkers.map((marker) {
                    return Marker(
                      point: marker.location,
                      width: 80,
                      height: 80,
                      child: Tooltip(
                        message: 'User: ${marker.userId.substring(0, 6)}...\nStatus: ${marker.status.name}',
                        child: _getMarkerIcon(marker.status),
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
        _buildFilterChips(),
      ],
    );
  }

  Widget _getMarkerIcon(TouristStatus status) {
    switch (status) {
      case TouristStatus.sos:
        return const Icon(Icons.warning, color: Colors.red, size: 40);
      case TouristStatus.attention:
        return const Icon(Icons.priority_high, color: Colors.orangeAccent, size: 35);
      case TouristStatus.normal:
      default:
        return const Icon(Icons.person_pin_circle, color: Colors.deepPurple, size: 35);
    }
  }

  Widget _buildFilterChips() {
    return Positioned(
      top: 10,
      left: 0,
      right: 0,
      child: Container(
        alignment: Alignment.center,
        child: Wrap(
          spacing: 8.0,
          children: [
            FilterChip(
              label: const Text('All Tourists'),
              selected: _activeFilter == FilterType.all,
              onSelected: (selected) {
                if (selected) setState(() => _activeFilter = FilterType.all);
              },
            ),
            FilterChip(
              label: const Text('SOS Alerts'),
              selected: _activeFilter == FilterType.sos,
              selectedColor: Colors.red.withOpacity(0.5),
              onSelected: (selected) {
                if (selected) setState(() => _activeFilter = FilterType.sos);
              },
            ),
            FilterChip(
              label: const Text('Needs Attention'),
              selected: _activeFilter == FilterType.attention,
              selectedColor: Colors.orange.withOpacity(0.5),
              onSelected: (selected) {
                if (selected) setState(() => _activeFilter = FilterType.attention);
              },
            ),
          ],
        ),
      ),
    );
  }
}
