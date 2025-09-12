import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/supabase_config.dart'; 

class AppState with ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  
  User? _currentUser;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  User? get currentUser => _currentUser;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isLoading => _isLoading;

  AppState() {
    _initializeApp();
  }

  Future<void> _initializeApp() async {    
    _currentUser = SupabaseConfig.client.auth.currentUser;
    
    if (_currentUser != null) {
      await _loadUserProfile(_currentUser!.id);
    } else {
      _isLoading = false;
      notifyListeners();
    }

    SupabaseConfig.client.auth.onAuthStateChange.listen((AuthState state) async {
      _currentUser = state.session?.user;
      if (_currentUser != null) {
        await _loadUserProfile(_currentUser!.id);
      } else {
        _userProfile = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> _loadUserProfile(String userId) async {
    try {
      _userProfile = await _databaseService.getUserProfile(userId);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user profile: $e');
      }
    }
  }

  Future<void> signIn(String email, String password) async {
    await _authService.signIn(email: email, password: password);
    // Auth state listener will handle profile loading and state updates
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String role,
    required String fullName,
  }) async {
    await _authService.signUp(
        email: email, password: password, role: role, fullName: fullName);
    // Auth state listener will handle profile loading and state updates
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    _userProfile = null;
    notifyListeners();
  }
}
