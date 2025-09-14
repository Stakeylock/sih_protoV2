import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import 'digital_id_service.dart';

class DatabaseService {
  final SupabaseClient _client = SupabaseManager.client;

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        debugPrint('User profile not yet available for $userId'); // no row yet
        return null;
      }
      rethrow;
    }
  }

  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
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
        'status': 'critical',
      });
    } catch (e) {
      debugPrint('Error creating SOS incident: $e');
    }
  }

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
      {
        'name': 'Main Police Station',
        'latitude': 17.3850,
        'longitude': 78.4867,
      },
      {'name': 'General Hospital', 'latitude': 17.4065, 'longitude': 78.4758},
      {
        'name': 'Tourist Information Center',
        'latitude': 17.3616,
        'longitude': 78.4747,
      },
    ];
  }

  Future<DigitalId?> getDigitalId(String userId) async {
    final data = await _client
        .from('digital_ids')
        .select('did, method, public_key_multibase, key_type, issued_at')
        .eq('id', userId) // was 'user_id'
        .maybeSingle();
    if (data == null) return null;
    return DigitalId.fromMap(data);
  }

  Future<void> upsertDigitalId({
    required String userId,
    required DigitalId id,
  }) async {
    await _client
        .from('digital_ids')
        .upsert({
          'id': userId, // was 'user_id'
          'did': id.did,
          'method': id.method,
          'public_key_multibase': id.publicKeyMultibase,
          'key_type': id.keyType,
          'issued_at': id.issuedAt.toIso8601String(),
        })
        .select()
        .maybeSingle();
  }

  Future<Map<String, dynamic>?> getKycInfo(String userId) async {
    final data = await _client
        .from('kyc_info')
        .select(
          'id, doc_type_uploaded, full_name_ext, dob_ext, id_num_ext, is_verified',
        )
        .eq('id', userId) // change to .eq('user_id', userId) if needed
        .maybeSingle();
    return data;
  }

  Future<void> upsertKycDraft({
    required String userId,
    required String docTypeUploaded,
  }) async {
    await _client
        .from('kyc_info')
        .upsert({
          'id': userId, // or user_id: userId
          'doc_type_uploaded': docTypeUploaded,
          'is_verified': false,
        })
        .select()
        .maybeSingle();
  }
}
