import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../services/supabase_config.dart';

// Digital ID issuance service (your Node/Edge API wrapper)
import '../services/digital_id_service.dart';

// The DigitalId model lives in DatabaseService for now.
// If you move it to models/digital_id.dart, import from there instead.
import '../services/database_service.dart' show DigitalId;

class AppState with ChangeNotifier {
  // Services
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  final LocationService _locationService = LocationService();
  final DigitalIdService _didService = DigitalIdService();

  // Configure where your Node API runs; move to env later.
  static const String _didApiBase = 'http://localhost:8787';

  // State
  User? _currentUser;
  Map<String, dynamic>? _userProfile;
  Position? _currentPosition;
  bool _isLoading = true;

  // Getters
  User? get currentUser => _currentUser;
  Map<String, dynamic>? get userProfile => _userProfile;
  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;

  AppState() {
    _initializeApp();
  }

  // Initialize: resolve initial session first, then listen to changes
  Future<void> _initializeApp() async {
    await SupabaseManager.initialize(); // Ensure Supabase is ready
    // 1) Read the initial session immediately after initialize
    final session = SupabaseManager.client.auth.currentSession;
    _currentUser = session?.user;

    if (_currentUser != null) {
      // 2) If a user exists on cold start, fully prepare state before ending loading
      await _ensureDigitalIdProvisioned();
      await _loadUserProfile(_currentUser!.id);
    }

    // 3) End initial loading after session/profile readiness
    _isLoading = false;
    notifyListeners();

    // 4) Listen for subsequent auth changes (sign-in/out, refresh, etc.)
    SupabaseManager.client.auth.onAuthStateChange.listen((data) async {
      final Session? s = data.session;
      _currentUser = s?.user;

      if (_currentUser != null) {
        // Reflect loading while fetching profile to avoid flicker/misroute
        _isLoading = true;
        notifyListeners();
        try {
          await _ensureDigitalIdProvisioned();
          await _loadUserProfile(_currentUser!.id);
        } finally {
          _isLoading = false;
          notifyListeners();
        }
      } else {
        // Signed out or session cleared
        _userProfile = null;
        _currentPosition = null;
        _locationService.stopTracking();
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  // Ensure a DID exists for the user (provision once)
  Future<void> _ensureDigitalIdProvisioned() async {
    final user = SupabaseManager.client.auth.currentUser;
    if (user == null) return;

    final existing = await _databaseService.getDigitalId(user.id);
    if (existing != null) return;

    final issued = await issueDidFromApi(apiBase: _didApiBase, userId: user.id);
    await _databaseService.upsertDigitalId(userId: user.id, id: issued);
  }

  // Load the user's profile and start tracking if Tourist
  Future<void> _loadUserProfile(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _userProfile = await _databaseService.getUserProfile(userId);
      if (_userProfile != null && _userProfile!['role'] == 'Tourist') {
        _locationService.startTracking(userId, _databaseService).listen((position) {
          _currentPosition = position;
          notifyListeners();
        });
      } else {
        _locationService.stopTracking();
        _currentPosition = null;
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============ Auth API passthroughs ============
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
    } catch (_) {
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
    } catch (_) {
      return 'An unexpected error occurred.';
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  // ============ Business actions ============
  Future<void> sendPanicAlert() async {
    if (_currentUser != null && _currentPosition != null) {
      await _databaseService.createSosIncident(
        userId: _currentUser!.id,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );
    }
  }

  // ============ Digital ID issuance wrapper (missing earlier) ============
  // Issues a DID via external API and maps it into the app's DigitalId model.
  Future<DigitalId> issueDidFromApi({
    required String apiBase,
    required String userId,
  }) async {
    // Expect DigitalIdService to call the API and return a plain map:
    // { did, method, public_key_multibase, key_type, issued_at }
    final map = await _didService.issueNewDid(
      apiBase: apiBase,
      userId: userId,
    );
    // Map to our model. If your DigitalIdService already returns DigitalId,
    // adjust accordingly and remove this conversion.
    return DigitalId.fromMap(map);
  }
}
