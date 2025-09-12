import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

class AuthService {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String role,
    required String fullName,
  }) async {
    final AuthResponse res = await _client.auth.signUp(
      email: email,
      password: password,
    );

    if (res.user != null) {
      await _client.from('profiles').insert({
        'id': res.user!.id,
        'email': email,
        'role': role.toLowerCase().replaceAll(' ', '_'),
        'full_name': fullName,
      });
    }

    return res;
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
