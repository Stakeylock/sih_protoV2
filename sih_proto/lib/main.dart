import 'package:flutter/material.dart';
import 'package:sih_proto/screens/auth_screens.dart';
import 'package:sih_proto/services/supabase_config.dart';
import 'package:sih_proto/providers/app_state.dart';
import 'package:provider/provider.dart';
import 'package:sih_proto/screens/tourist_dashboard.dart';
import 'package:sih_proto/screens/admin_dashboard.dart';
import 'package:sih_proto/screens/police_dashboard.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  // Initialize Supabase
  await SupabaseConfig.initialize();
  
  runApp(const SihProtoApp());
}

class SihProtoApp extends StatelessWidget {
  const SihProtoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: Consumer<AppState>(
        builder: (context, appState, child) {
          return MaterialApp(
            title: 'Tourist Safety System',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              textTheme: GoogleFonts.latoTextTheme(
                Theme.of(context).textTheme,
              ),
            ),
            home: _buildHomeScreen(appState),
            routes: {
              '/login': (context) => const LoginPage(),
              '/register': (context) => const RegisterPage(),
              '/tourist-dashboard': (context) => const TouristDashboard(),
              '/admin-dashboard': (context) => const AdminDashboard(),
              '/police-dashboard': (context) => const PoliceDashboard(),
            },
          );
        },
      ),
    );
  }

  Widget _buildHomeScreen(AppState appState) {
    if (appState.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1a202c),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              SizedBox(height: 20),
              Text('Loading Your Safe Journey...', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    if (appState.currentUser == null) {
      return const LoginPage();
    }

    final userRole = appState.userProfile?['role'] ?? 'tourist';
    
    switch (userRole) {
      case 'admin':
        return const AdminDashboard();
      case 'police':
        return const PoliceDashboard();
      case 'tourist':
      default:
        return const TouristDashboard();
    }
  }
}

