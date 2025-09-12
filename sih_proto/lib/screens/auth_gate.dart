import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sih_proto/providers/app_state.dart';
import 'package:sih_proto/screens/admin_dashboard.dart';
import 'package:sih_proto/screens/auth_screens.dart';
import 'package:sih_proto/screens/police_dashboard.dart';
import 'package:sih_proto/screens/splash_screen.dart';
import 'package:sih_proto/screens/tourist_dashboard.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // This Consumer widget will rebuild whenever AppState changes.
    return Consumer<AppState>(
      builder: (context, appState, child) {
        
        // While the app is doing its initial check, show the splash screen.
        // This prevents a flash of the login screen for already-logged-in users.
        if (appState.isLoading && appState.currentUser == null) {
          return const SplashScreen();
        }

        // If a user is logged in, show the appropriate dashboard.
        if (appState.currentUser != null) {
          final userRole = appState.userProfile?['role'] ?? 'Tourist';
          switch (userRole) {
            case 'Admin':
              return const AdminDashboard();
            case 'Police':
              return const PoliceDashboard();
            case 'Tourist':
            default:
              return const TouristDashboard();
          }
        }
        
        // If no user is logged in, show the login page.
        return const LoginPage();
      },
    );
  }
}
