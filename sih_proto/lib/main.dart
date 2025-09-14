import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:sih_proto/providers/app_state.dart';
import 'package:sih_proto/screens/admin/admin_dashboard_screen.dart';
import 'package:sih_proto/screens/auth_gate.dart';
import 'package:sih_proto/screens/auth_screens.dart';
import 'package:sih_proto/screens/police_dashboard.dart';
import 'package:sih_proto/screens/tourist_dashboard.dart';
// UPDATED: Changed the import to point to the consolidated manager file
import 'package:sih_proto/services/supabase_config.dart';
import 'package:sih_proto/utils/app_theme.dart';

import 'package:sih_proto/screens/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  // UPDATED: Changed the initialization call to the new SupabaseManager class
  await SupabaseManager.initialize();

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
        home: const AuthGate(),
        routes: {
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/tourist-dashboard': (context) => const TouristDashboard(),
          '/admin-dashboard': (context) => const AdminDashboardScreen(),
          '/police-dashboard': (context) => const PoliceDashboard(),
          '/chat': (context) => const ChatScreen(),
        },
      ),
    );
  }
}
