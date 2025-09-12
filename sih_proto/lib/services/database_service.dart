import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

class DatabaseService {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response =
          await _client.from('profiles').select().eq('id', userId).single();
      return response;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        debugPrint('User profile not yet available for $userId');
        return null;
      }
      rethrow;
    }
  }

  Future<void> updateUserProfile(
      String userId, Map<String, dynamic> updates) async {
    await _client.from('profiles').update(updates).eq('id', userId);
  }

  Future<void> updateUserLocation({
    required String userId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _client.from('tourist_locations').insert({
        'user_id': userId,
        'latitude': latitude,
        'longitude': longitude,
      });
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

  Future<void> createSosIncident({
    required String userId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _client.from('incidents').insert({
        'title': 'SOS Alert',
        'description': 'User triggered the panic button.',
        'latitude': latitude,
        'longitude': longitude,
        'reported_by': userId,
        'status': 'critical'
      });
    } catch (e) {
      debugPrint('Error creating SOS incident: $e');
    }
  }

  // New method to report an incident
  Future<void> reportIncident({
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    required String userId,
  }) async {
    await _client.from('incidents').insert({
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'reported_by': userId,
    });
  }

  // New method to get safe zones (returns mock data for now)
  Future<List<Map<String, dynamic>>> getSafeZones() async {
    // In a real app, this would fetch from a 'safe_zones' table
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    return [
      {'name': 'Main Police Station', 'latitude': 17.3850, 'longitude': 78.4867},
      {'name': 'General Hospital', 'latitude': 17.4065, 'longitude': 78.4758},
      {'name': 'Tourist Information Center', 'latitude': 17.3616, 'longitude': 78.4747},
    ];
  }

  // New method to get a user's digital ID
  Future<Map<String, dynamic>?> getDigitalId(String userId) async {
    try {
      final response = await _client.from('digital_ids').select().eq('id', userId).single();
      return response;
    } catch (e) {
      debugPrint("Could not fetch digital ID: $e");
      return null;
    }
  }
}

