import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../services/supabase_config.dart';
import '../services/digital_id_service.dart';
import '../services/database_service.dart' show DigitalId;

class AppState with ChangeNotifier {
  // Services
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  final LocationService _locationService = LocationService();
  final DigitalIdService _didService = DigitalIdService();

  static const String _didApiBase = 'http://localhost:8787';

  // State
  User? _currentUser;
  Map<String, dynamic>? _userProfile;
  Position? _currentPosition;
  bool _isLoading = true;

  // --- SOS Real-time State ---
  StreamSubscription<List<Map<String, dynamic>>>? _alertSubscription;
  List<Map<String, dynamic>> _activeAlerts = [];
  bool _isSosActive = false;
  String? _activeSosId;

  // Getters
  User? get currentUser => _currentUser;
  Map<String, dynamic>? get userProfile => _userProfile;
  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  
  List<Map<String, dynamic>> get activeAlerts => _activeAlerts;
  bool get isSosActive => _isSosActive;
  String? get activeSosId => _activeSosId;

  AppState() {
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await SupabaseManager.initialize();
    final session = SupabaseManager.client.auth.currentSession;
    _currentUser = session?.user;

    if (_currentUser != null) {
      await _ensureDigitalIdProvisioned();
      await _loadUserProfile(_currentUser!.id);
    }

    _isLoading = false;
    notifyListeners();

    SupabaseManager.client.auth.onAuthStateChange.listen((data) async {
      final Session? s = data.session;
      _currentUser = s?.user;

      if (_currentUser != null) {
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
        // Signed out
        _userProfile = null;
        _currentPosition = null;
        _locationService.stopTracking();
        _alertSubscription?.cancel();
        _activeAlerts = [];
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _ensureDigitalIdProvisioned() async {
    final user = SupabaseManager.client.auth.currentUser;
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
      if (_userProfile != null) {
        if (_userProfile!['role'] == 'Tourist') {
          _locationService.startTracking(userId, _databaseService).listen((position) {
            _currentPosition = position;
            notifyListeners();
          });
          // Stop listening for alerts if user is not an admin
          _alertSubscription?.cancel();
        } else if (_userProfile!['role'] == 'admin') {
          listenToSOSAlerts();
        }
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

  // ============ SOS & Real-time Functionality ============

  // Tourist action: Starts the SOS process
  Future<String?> sendPanicAlert() async {
    if (_currentUser == null || _currentPosition == null) return null;

    final response = await SupabaseManager.client
        .from('sos_incidents')
        .insert({
          'user_id': _currentUser!.id,
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
          'status': 'active',
          'emergency_type': 'unclassified', // AI classification would happen here
        })
        .select()
        .single();
    
    _isSosActive = true;
    _activeSosId = response['id'];
    notifyListeners();
    return _activeSosId;
  }
  
  // Tourist action: Stops the SOS process
  Future<void> stopPanicAlert() async {
    if(_activeSosId != null) {
      await updateAlertStatus(_activeSosId!, 'resolved');
      _isSosActive = false;
      _activeSosId = null;
      notifyListeners();
    }
  }

  // Admin action: Listens for any new alerts
  void listenToSOSAlerts() {
    _alertSubscription?.cancel();
    _alertSubscription = SupabaseManager.client
        .from('sos_incidents')
        .stream(primaryKey: ['id'])
        .eq('status', 'active')
        .listen((data) {
          _activeAlerts = data;
          notifyListeners();
        }, onError: (error) {
           debugPrint('Error listening to SOS alerts: $error');
        });
  }
  
  // Admin action: Updates alert status
  Future<void> updateAlertStatus(String alertId, String status) async {
    await SupabaseManager.client
      .from('sos_incidents')
      .update({'status': status})
      .eq('id', alertId);
  }

  // Admin action: Forwards alert to a team
  Future<void> forwardAlert(String alertId, String team) async {
     await SupabaseManager.client
      .from('sos_incidents')
      .update({'status': 'forwarded', 'forwarded_to': team})
      .eq('id', alertId);
  }


  // ============ Digital ID issuance wrapper ============
  Future<DigitalId> issueDidFromApi({
    required String apiBase,
    required String userId,
  }) async {
    final map = await _didService.issueNewDid(
      apiBase: apiBase,
      userId: userId,
    );
    return DigitalId.fromMap(map);
  }
}

