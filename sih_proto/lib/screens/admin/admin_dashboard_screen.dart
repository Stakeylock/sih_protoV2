// lib/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sih_proto/providers/app_state.dart';

import 'package:sih_proto/screens/admin/features/broadcast_screen.dart';
import 'package:sih_proto/screens/admin/features/content_management_screen.dart';
import 'package:sih_proto/screens/admin/features/guide_management_screen.dart';
import 'package:sih_proto/screens/admin/features/live_monitoring_screen.dart';
import 'package:sih_proto/screens/admin/features/role_management_screen.dart';
import 'package:sih_proto/screens/admin/features/safety_zone_manager.dart';
import 'package:sih_proto/screens/admin/features/service_management_screen.dart';
import 'package:sih_proto/screens/admin/features/user_verification_screen.dart';
import 'package:sih_proto/screens/admin/features/spots_with_checkpoints_screen.dart';
import 'package:sih_proto/screens/admin/features/women_child_safety_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final userName = appState.userProfile?['full_name'] ?? 'Admin';

    return Scaffold(
      backgroundColor: const Color(0xFF1a202c),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2d3748),
        elevation: 0,
        title: Text(
          'Welcome, $userName',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AppState>(context, listen: false).signOut();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.05,
        children: [
          _DashboardCard(
            title: 'Safety Zones',
            icon: Icons.security_rounded,
            color: Colors.green.shade400,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SafetyZoneManager()),
            ),
          ),
          _DashboardCard(
            title: 'Live Monitoring',
            icon: Icons.map_rounded,
            color: Colors.purple.shade400,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LiveMonitoringScreen()),
            ),
          ),
          _DashboardCard(
            title: 'User Verification',
            icon: Icons.verified_user_rounded,
            color: Colors.cyan.shade400,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserVerificationScreen()),
            ),
          ),
          _DashboardCard(
            title: 'Role Management',
            icon: Icons.manage_accounts_rounded,
            color: Colors.blue.shade400,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RoleManagementScreen()),
            ),
          ),
          _DashboardCard(
            title: 'Manage Guides and Transportation',
            icon: Icons.travel_explore_rounded,
            color: Colors.teal.shade400,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GuideManagementScreen()),
            ),
          ),
          _DashboardCard(
            title: 'Manage Services',
            icon: Icons.medical_services_rounded,
            color: Colors.red.shade400,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ServiceManagementScreen()),
            ),
          ),
          _DashboardCard(
            title: 'Broadcast Alert',
            icon: Icons.campaign_rounded,
            color: Colors.orange.shade400,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BroadcastScreen()),
            ),
          ),
          _DashboardCard(
            title: 'Manage Content',
            icon: Icons.edit_document,
            color: Colors.pink.shade300,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ContentManagementScreen()),
            ),
          ),
          _DashboardCard(
            title: 'Spots & Checkpoints',
            icon: Icons.route,
            color: Colors.indigo.shade400,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const SpotsWithCheckpointsScreen()),
            ),
          ),

          // _DashboardCard
          _DashboardCard(
            title: 'Women & Child Safety',
            icon: Icons.sos_rounded,
            color: Colors.deepPurpleAccent.shade200,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const WomenChildSafetyScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2d3748),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
