import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

class AuthService {
  final SupabaseClient _client = SupabaseManager.client;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String role,
    required String fullName,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'role': role,
        'full_name': fullName,
      },
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;
}

