import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/digital_id_service.dart';
import '../services/location_service.dart';
import '../services/supabase_config.dart';

class AppState with ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  final LocationService _locationService = LocationService();

  // Configure where your Node API runs; move to env later.
  static const String _didApiBase = 'http://localhost:8787';

  User? _currentUser;
  Map<String, dynamic>? _userProfile;
  Position? _currentPosition;
  bool _isLoading = true;

  User? get currentUser => _currentUser;
  Map<String, dynamic>? get userProfile => _userProfile;
  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;

  AppState() {
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await SupabaseConfig.initialize();
    _currentUser = SupabaseConfig.client.auth.currentUser;
    if (_currentUser != null) {
      await _ensureDigitalIdProvisioned();
      await _loadUserProfile(_currentUser!.id);
    } else {
      _isLoading = false;
      notifyListeners();
    }

    // Listen to auth changes globally.[3]
    SupabaseConfig.client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      _currentUser = session?.user;
      if (_currentUser != null) {
        await _ensureDigitalIdProvisioned();
        _loadUserProfile(_currentUser!.id);
      } else {
        _userProfile = null;
        _currentPosition = null;
        _locationService.stopTracking();
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _ensureDigitalIdProvisioned() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;
    final existing = await _databaseService.getDigitalId(user.id);
    if (existing != null) return;
    final issued = await issueDidFromApi(apiBase: _didApiBase, userId: user.id);
    await _databaseService.upsertDigitalId(userId: user.id, id: issued);
  }

  Future<void> _loadUserProfile(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _userProfile = await _databaseService.getUserProfile(userId);
      if (_userProfile != null && _userProfile!['role'] == 'Tourist') {
        _locationService.startTracking(userId, _databaseService).listen((
          position,
        ) {
          _currentPosition = position;
          notifyListeners();
        });
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      await _authService.signUp(
        email: email,
        password: password,
        role: role,
        fullName: fullName,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _authService.signIn(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  Future<void> sendPanicAlert() async {
    if (_currentUser != null && _currentPosition != null) {
      await _databaseService.createSosIncident(
        userId: _currentUser!.id,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}
