import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sih_proto/providers/app_state.dart';
import 'package:sih_proto/screens/auth_screens.dart';
import 'package:sih_proto/screens/tourist_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  AppState? _appState; // Store reference to AppState

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Save reference to AppState
    _appState = Provider.of<AppState>(context, listen: false);
    // Initial setup moved from initState to ensure context is valid
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appState!.addListener(_onAppStateChanged);
      _checkAndNavigate(_appState!);
    });
  }

  void _onAppStateChanged() {
    _checkAndNavigate(_appState!);
  }

  void _checkAndNavigate(AppState appState) {
    // Only navigate if loading is false. This prevents premature navigation.
    if (!appState.isLoading) {
      // Remove the listener before navigating to avoid multiple navigation attempts.
      appState.removeListener(_onAppStateChanged);
      if (appState.currentUser != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const TouristDashboard()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    }
  }

  @override
  void dispose() {
    // Use stored _appState reference instead of Provider.of
    _appState?.removeListener(_onAppStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Loading Tourist Safety System...'),
          ],
        ),
      ),
    );
  }
}