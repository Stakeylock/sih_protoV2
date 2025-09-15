import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/digital_id_service.dart';
import '../services/location_service.dart';
import '../services/supabase_config.dart';

class AppState with ChangeNotifier {
  // Services
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  final LocationService _locationService = LocationService();

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
    await SupabaseManager.initialize(); // Ensure Supabase is ready before reading session [1].

    // 1) Read the initial session immediately after initialize
    final session = SupabaseManager.client.auth.currentSession;
    debugPrint('Initial session present: ${session != null}');
    _currentUser = session?.user; // Use initial session user to determine startup route [1].

    // 2) If a user exists on cold start, fully prepare state before ending loading
    if (_currentUser != null) {
      debugPrint('Initial user: ${_currentUser!.id}');
      await _ensureDigitalIdProvisioned(); // Provision DID only once for the user [1].
      await _loadUserProfile(_currentUser!.id); // Load profile so role-based routing is correct [2].
    }

    // 3) End initial loading only after session/profile readiness
    _isLoading = false;
    notifyListeners(); // Allow AuthGate to evaluate with a fully prepared state [2].

    // 4) Listen for subsequent auth changes (sign-in/out, refresh, etc.)
    SupabaseManager.client.auth.onAuthStateChange.listen((data) async {
      debugPrint('Auth event: ${data.event}, session present = ${data.session != null}');
      _currentUser = data.session?.user; // Update user on every auth event emission [2].

      if (_currentUser != null) {
        // Reflect loading while fetching profile so UI can show Splash instead of flicker
        _isLoading = true;
        notifyListeners(); // Keep Splash visible during profile fetch to avoid defaulting to Tourist [2].

        try {
          await _ensureDigitalIdProvisioned(); // Ensure DID exists after sign-in as well [1].
          await _loadUserProfile(_currentUser!.id); // Refresh profile so role-based routing updates correctly [2].
        } finally {
          _isLoading = false;
          notifyListeners(); // Unblock routing after profile is ready [2].
        }
      } else {
        // Signed out or session cleared
        _userProfile = null; // Clear profile on sign-out so UI returns to login [2].
        _currentPosition = null; // Stop tracking location on sign-out for privacy [1].
        _locationService.stopTracking(); // Ensure background tracking is stopped [1].
        _isLoading = false;
        notifyListeners(); // Update UI to show login [2].
      }
    });
  }

  // Ensure a DID exists for the user
  Future<void> _ensureDigitalIdProvisioned() async {
    final user = SupabaseManager.client.auth.currentUser;
    if (user == null) return; // No-op if not authenticated [1].

    final existing = await _databaseService.getDigitalId(user.id);
    if (existing != null) return; // Skip if already provisioned [1].

    final issued = await issueDidFromApi(apiBase: _didApiBase, userId: user.id);
    await _databaseService.upsertDigitalId(userId: user.id, id: issued); // Persist the issued DID [1].
  }

  // Load the user's profile and start tracking if Tourist
  Future<void> _loadUserProfile(String userId) async {
    _isLoading = true;
    notifyListeners(); // Keep Splash while fetching profile to avoid misrouting [2].
    try {
      _userProfile = await _databaseService.getUserProfile(userId); // Fetch role and other profile fields from DB [1].

      if (_userProfile != null && _userProfile!['role'] == 'Tourist') {
        _locationService.startTracking(userId, _databaseService).listen((position) {
          _currentPosition = position; // Continuously update current position for Tourist features [1].
          notifyListeners(); // Notify UI for live location-bound widgets [1].
        });
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e'); // Log profile load failures for debugging [1].
    } finally {
      _isLoading = false;
      notifyListeners(); // Allow AuthGate to route with an actual role value [2].
    }
  }

  // Auth API passthroughs returning an error message or null on success
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
      ); // Delegate sign-up, which may require email confirmation depending on project settings [1].
      return null; // Successful sign-up returns no error message [1].
    } on AuthException catch (e) {
      return e.message; // Surface Supabase auth errors for UI display [1].
    } catch (e) {
      return 'An unexpected error occurred.'; // Generic fallback error message [1].
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _authService.signIn(email: email, password: password); // Listener will update current user and profile [2].
      return null; // Null indicates success to the UI layer [1].
    } on AuthException catch (e) {
      return e.message; // Return readable auth error messages [1].
    } catch (e) {
      return 'An unexpected error occurred.'; // Generic fallback error message [1].
    }
  }

  Future<void> signOut() async {
    await _authService.signOut(); // onAuthStateChange will clear profile and position, updating UI to login [2].
  }

  // Business actions
  Future<void> sendPanicAlert() async {
    if (_currentUser != null && _currentPosition != null) {
      await _databaseService.createSosIncident(
        userId: _currentUser!.id,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      ); // Store SOS with current coordinates for responders [1].
    }
  }
}
