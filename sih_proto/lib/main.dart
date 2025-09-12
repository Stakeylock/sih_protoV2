import 'package:flutter/material.dart';
import 'package:sih_proto/providers/app_state.dart';
import 'package:provider/provider.dart';
import 'package:sih_proto/screens/admin_dashboard.dart';
import 'package:sih_proto/screens/auth_gate.dart';
import 'package:sih_proto/screens/auth_screens.dart';
import 'package:sih_proto/screens/police_dashboard.dart';
import 'package:sih_proto/screens/tourist_dashboard.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sih_proto/services/supabase_config.dart';
import 'package:sih_proto/utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await SupabaseConfig.initialize();

  runApp(const SihProtoApp());
}

class SihProtoApp extends StatelessWidget {
  const SihProtoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp(
        title: 'Tourist Safety System',
        theme: AppTheme.theme,
        debugShowCheckedModeBanner: false,
        // The AuthGate is now the single source of truth for navigation.
        home: const AuthGate(),
        routes: {
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/tourist-dashboard': (context) => const TouristDashboard(),
          '/admin-dashboard': (context) => const AdminDashboard(),
          '/police-dashboard': (context) => const PoliceDashboard(),
        },
      ),
    );
  }
}

