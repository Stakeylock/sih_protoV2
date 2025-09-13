import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Enum to represent the status of a tourist
enum TouristStatus { normal, sos, attention }

class TouristMarker {
  final String userId;
  final LatLng location;
  final TouristStatus status;

  TouristMarker({
    required this.userId,
    required this.location,
    this.status = TouristStatus.normal,
  });
}

class TouristLocationService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<TouristMarker>> getTouristLocationsStream() {
    try {
      // Assuming 'tourist_locations' table has columns: 'user_id', 'latitude', 'longitude', and 'status'
      // The 'status' column would be a TEXT field storing values like 'normal', 'sos', 'attention'.
      return _client
          .from('tourist_locations')
          .stream(primaryKey: ['id'])
          .map((listOfMaps) {
            final List<TouristMarker> markers = [];
            if (listOfMaps.isEmpty) return markers;

            for (final map in listOfMaps) {
              final userId = map['user_id'] as String?;
              final lat = map['latitude'] as double?;
              final lon = map['longitude'] as double?;
              final statusString = map['status'] as String? ?? 'normal';

              if (userId != null && lat != null && lon != null) {
                markers.add(
                  TouristMarker(
                    userId: userId,
                    location: LatLng(lat, lon),
                    status: _parseStatus(statusString),
                  ),
                );
              }
            }
            
            final latestLocations = <String, TouristMarker>{};
            for (final marker in markers) {
              latestLocations[marker.userId] = marker;
            }
            return latestLocations.values.toList();
          });
    } catch (e) {
      debugPrint('Error getting tourist locations stream: $e');
      return Stream.value([]); // Return an empty stream on error
    }
  }

  // Helper function to convert string from DB to Enum
  TouristStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'sos':
        return TouristStatus.sos;
      case 'attention':
        return TouristStatus.attention;
      default:
        return TouristStatus.normal;
    }
  }
}

