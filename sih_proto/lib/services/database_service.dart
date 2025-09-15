// lib/services/database_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

// Local model for Digital ID mapping
class DigitalId {
  final String did;
  final String method;
  final String publicKeyMultibase;
  final String keyType;
  final DateTime issuedAt;

  const DigitalId({
    required this.did,
    required this.method,
    required this.publicKeyMultibase,
    required this.keyType,
    required this.issuedAt,
  });

  factory DigitalId.fromMap(Map<String, dynamic> map) {
    return DigitalId(
      did: (map['did'] ?? '').toString(),
      method: (map['method'] ?? '').toString(),
      publicKeyMultibase: (map['public_key_multibase'] ?? '').toString(),
      keyType: (map['key_type'] ?? '').toString(),
      issuedAt: _parseDate(map['issued_at']),
    );
  }

  Map<String, dynamic> toMap({required String userId}) {
    return {
      'id': userId, // PK equals user id in your schema
      'did': did,
      'method': method,
      'public_key_multibase': publicKeyMultibase,
      'key_type': keyType,
      'issued_at': issuedAt.toIso8601String(),
    };
  }

  static DateTime _parseDate(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) {
      return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

class DatabaseService {
  final SupabaseClient _client = SupabaseManager.client;

  // ------------------ Profiles ------------------

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final res = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle(); // 0 or 1 row
      return res as Map<String, dynamic>?;
    } on PostgrestException catch (e) {
      // PGRST116: Results contain 0 rows (single)
      if (e.code == 'PGRST116') {
        debugPrint('User profile not yet available for $userId');
        return null;
      }
      rethrow;
    }
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) {
    return _client.from('profiles').update(updates).eq('id', userId);
  }

  // ------------------ Location tracking ------------------

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

  // ------------------ Incidents ------------------

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

  // ------------------ Safe zones (placeholder) ------------------

  Future<List<Map<String, dynamic>>> getSafeZones() async {
    await Future.delayed(const Duration(seconds: 1));
    return const [
      {'name': 'Main Police Station', 'latitude': 17.3850, 'longitude': 78.4867},
      {'name': 'General Hospital', 'latitude': 17.4065, 'longitude': 78.4758},
      {'name': 'Tourist Information Center', 'latitude': 17.3616, 'longitude': 78.4747},
    ];
  }

  // ------------------ Digital ID ------------------

  // Schema assumption:
  // table: digital_ids
  // columns: id (PK, user id), did, method, public_key_multibase, key_type, issued_at
  Future<DigitalId?> getDigitalId(String userId) async {
    final data = await _client
        .from('digital_ids')
        .select('did, method, public_key_multibase, key_type, issued_at')
        .eq('id', userId)
        .maybeSingle(); // returns Map<String, dynamic>? or null
    if (data == null) return null;
    return DigitalId.fromMap(data as Map<String, dynamic>);
  }

  Future<void> upsertDigitalId({
    required String userId,
    required DigitalId id,
  }) async {
    await _client
        .from('digital_ids')
        .upsert(id.toMap(userId: userId))
        .select()
        .maybeSingle();
  }

  // ------------------ KYC ------------------

  Future<Map<String, dynamic>?> getKycInfo(String userId) async {
    final data = await _client
        .from('kyc_info')
        .select(
            'id, doc_type_uploaded, full_name_ext, dob_ext, id_num_ext, is_verified')
        .eq('id', userId)
        .maybeSingle();
    return data as Map<String, dynamic>?;
  }

  Future<void> upsertKycDraft({
    required String userId,
    required String docTypeUploaded,
  }) async {
    await _client
        .from('kyc_info')
        .upsert({
          'id': userId,
          'doc_type_uploaded': docTypeUploaded,
          'is_verified': false,
        })
        .select()
        .maybeSingle();
  }

  // ------------------ Admin: spots with checkpoints ------------------

  // Requires FK: tourist_spot_checkpoints.spot_id -> tourist_spots.spot_id
  Future<List<Map<String, dynamic>>> getSpotsWithCheckpoints() async {
    final rows = await _client.from('tourist_spots').select('''
      spot_id,
      spot_name,
      spot_location,
      no_of_checkpoints,
      tourist_spot_checkpoints:tourist_spot_checkpoints (
        checkpoint_id,
        checkpoint_number,
        created_at,
        spot_id
      )
    ''').order('spot_name', ascending: true);

    final data = (rows as List).cast<Map<String, dynamic>>();

    // Sort checkpoints for display
    for (final r in data) {
      final cps =
          (r['tourist_spot_checkpoints'] as List? ?? const []).cast<Map<String, dynamic>>();
      cps.sort((a, b) => (a['checkpoint_number'] as num? ?? 0)
          .compareTo(b['checkpoint_number'] as num? ?? 0));
      r['tourist_spot_checkpoints'] = cps;
    }

    return data;
  }
}
