import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Data Models ---

// Represents a safety zone (geofence with a type)
class SafetyZone {
  final int id;
  final String name;
  final String zoneType; // 'green', 'orange', 'red'
  final List<LatLng> area;

  SafetyZone({
    required this.id,
    required this.name,
    required this.zoneType,
    required this.area,
  });

  factory SafetyZone.fromMap(Map<String, dynamic> map) {
    final List<dynamic> pointsData = map['area'] is String
        ? json.decode(map['area'])
        : map['area'];
    final List<LatLng> points = pointsData
        .map((p) => LatLng(
              (p[0] as num).toDouble(),
              (p[1] as num).toDouble(),
            ))
        .toList();

    return SafetyZone(
      id: map['id'],
      name: map['name'],
      zoneType: map['zone_type'] ?? 'green',
      area: points,
    );
  }
}

// Represents a user profile for role management
class UserProfile {
  final String id;
  final String fullName;
  final String role;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.role,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      fullName: map['full_name'] ?? 'N/A',
      role: map['role'] ?? 'Tourist',
    );
  }
}

class UnverifiedUser {
  final String id;
  final String name;
  final String email;

  UnverifiedUser({required this.id, required this.name, required this.email});
}

class Guide {
  final String id;
  String name;
  String languages;
  String specialization;

  Guide({
    required this.id,
    required this.name,
    required this.languages,
    required this.specialization,
  });
}

class ContentItem {
  final String id;
  final String title;
  final String type; // 'event' or 'contest'

  ContentItem({required this.id, required this.title, required this.type});
}

class VerifiedService {
  final String id;
  final String name;
  final String type;
  final String contact;

  VerifiedService({required this.id, required this.name, required this.type, required this.contact});
}


// --- Main Service Class ---

class SupabaseManager {
  
  // --- Initialization and Client Access ---

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      debug: kDebugMode,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  // --- AUTHENTICATION METHODS (for AppState) ---
  Future<void> signUp({
    required String email,
    required String password,
    required String role,
    required String fullName,
  }) async {
    await client.auth.signUp(
      email: email,
      password: password,
      data: {'role': role, 'full_name': fullName},
    );
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await client.from('profiles').select().eq('id', userId).single();
      return response;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') return null;
      rethrow;
    }
  }
  
  Future<void> createSosIncident({
    required String userId,
    required double latitude,
    required double longitude,
  }) async {
     await client.from('incidents').insert({
        'title': 'SOS Alert',
        'description': 'User triggered the panic button.',
        'latitude': latitude,
        'longitude': longitude,
        'reported_by': userId,
        'status': 'critical',
      });
  }

  // --- Admin: User Management ---
  Stream<List<UnverifiedUser>> getUnverifiedUsersStream() {
    return client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('is_verified', false)
        .map((maps) => maps
            .map((map) => UnverifiedUser(
                  id: map['id'],
                  name: map['full_name'] ?? 'No Name',
                  email: 'user@example.com', // Placeholder email
                ))
            .toList());
  }

  Future<void> verifyUser(String userId) async {
    await client.from('profiles').update({'is_verified': true}).eq('id', userId);
  }

  Future<void> deleteUser(String userId) async {
    await client.rpc('delete_user_by_id', params: {'user_id': userId});
  }


  // --- Admin: Safety Zone Management ---

  Future<List<SafetyZone>> getSafetyZones() async {
    final response = await client.from('geofences').select();
    return response.map((map) => SafetyZone.fromMap(map)).toList();
  }

  Future<void> addSafetyZone({
    required String name,
    required List<LatLng> area,
    required String zoneType,
  }) async {
    final areaJson = json.encode(area.map((p) => [p.latitude, p.longitude]).toList());
    await client.from('geofences').insert({
      'name': name,
      'area': areaJson,
      'zone_type': zoneType,
    });
  }

  // --- Admin: Role Management ---

  Future<List<UserProfile>> getAllUsers() async {
    final response = await client.from('profiles').select('id, full_name, role');
    return response.map((map) => UserProfile.fromMap(map)).toList();
  }

  Future<void> updateUserRole({
    required String userId,
    required String newRole,
  }) async {
    await client.from('profiles').update({'role': newRole}).eq('id', userId);
  }

  // --- Admin: Broadcast Notifications ---

  Future<void> sendBroadcastNotification({
    required String title,
    required String message,
    required int zoneId,
  }) async {
    await client.from('notifications').insert({
      'title': title,
      'message': message,
      'geofence_id': zoneId,
      'created_by': client.auth.currentUser!.id,
    });
  }

  // --- Admin: Tourist Monitoring ---

  Future<List<Map<String, dynamic>>> getTouristsInZone(int zoneId) async {
    final response = await client.rpc(
      'get_tourists_in_zone',
      params: {'zone_id': zoneId},
    );
    return List<Map<String, dynamic>>.from(response);
  }
  
  // --- ADMIN: GUIDE MANAGEMENT ---
  Future<List<Guide>> getGuides() async {
    final response = await client.from('guides').select();
    return response.map((item) => Guide(
      id: item['id'].toString(),
      name: item['name'],
      languages: item['languages'],
      specialization: item['specialization'],
    )).toList();
  }
  
  Future<void> addGuide(String name, String languages, String specialization) async {
    await client.from('guides').insert({
      'name': name,
      'languages': languages,
      'specialization': specialization,
    });
  }

  Future<void> updateGuide(Guide guide) async {
    await client
        .from('guides')
        .update({
          'name': guide.name,
          'languages': guide.languages,
          'specialization': guide.specialization,
        })
        .eq('id', guide.id);
  }

  Future<void> deleteGuide(String guideId) async {
    await client.from('guides').delete().eq('id', guideId);
  }


  // --- ADMIN: CONTENT MANAGEMENT ---
  Future<List<ContentItem>> getContentItems(String type) async {
    final response = await client.from('content_items').select().eq('type', type);
    return response.map((item) => ContentItem(
      id: item['id'].toString(),
      title: item['title'],
      type: item['type'],
    )).toList();
  }

  // --- ADMIN: SERVICE MANAGEMENT ---
    Future<List<VerifiedService>> getVerifiedServices() async {
    final response = await client.from('verified_services').select();
    return response.map((item) => VerifiedService(
      id: item['id'].toString(),
      name: item['name'],
      type: item['type'],
      contact: item['contact_info'],
    )).toList();
  }
}

