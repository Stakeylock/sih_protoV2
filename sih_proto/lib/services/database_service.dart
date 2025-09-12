import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

class DatabaseService {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    
    return response;
  }

  Future<void> updateUserProfile(
    String userId, 
    Map<String, dynamic> updates
  ) async {
    await _client
        .from('profiles')
        .update(updates)
        .eq('id', userId);
  }
  
  Future<List<Map<String, dynamic>>> getIncidents() async {
    final response = await _client.from('incidents').select();
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createIncident({
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    required String reportedBy,
  }) async {
    await _client.from('incidents').insert({
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'reported_by': reportedBy,
    });
  }

  Future<List<Map<String, dynamic>>> getSafeZones() async {
    final response = await _client.from('safe_zones').select();
    return List<Map<String, dynamic>>.from(response);
  }
}
