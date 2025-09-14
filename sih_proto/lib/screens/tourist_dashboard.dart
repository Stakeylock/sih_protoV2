import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:sih_proto/providers/app_state.dart';
import 'package:sih_proto/screens/chat_screen.dart';
import 'package:sih_proto/screens/digital_id_screen.dart';
import 'package:sih_proto/screens/live_map_screen.dart';
import 'package:sih_proto/screens/notifications_screen.dart';
import 'package:sih_proto/screens/report_incident_screen.dart';
import 'package:sih_proto/screens/safe_zones_screen.dart';
import 'package:sih_proto/utils/custom_icons.dart';

class TouristDashboard extends StatelessWidget {
  const TouristDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final userName = appState.userProfile?['full_name'] ?? 'Tourist';
    final currentPosition = appState.currentPosition;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AppState>(context, listen: false).signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WelcomeHeader(userName: userName),
              const SizedBox(height: 24),
              const _PanicButton(),
              const SizedBox(height: 24),
              _CurrentLocation(position: currentPosition),
              const SizedBox(height: 24),
              _FeaturesGrid(),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  final String userName;
  const _WelcomeHeader({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome Back,',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
        ),
        Text(
          userName,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
      ],
    );
  }
}

class _PanicButton extends StatelessWidget {
  const _PanicButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Provider.of<AppState>(context, listen: false).sendPanicAlert();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SOS Alert Sent! Help is on the way.'),
            backgroundColor: Colors.red,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.red, Color.fromARGB(255, 255, 82, 82)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Column(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 40),
            SizedBox(height: 8),
            Text(
              'SOS PANIC BUTTON',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentLocation extends StatelessWidget {
  final Position? position;
  const _CurrentLocation({this.position});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Location',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                const SizedBox(height: 4),
                if (position != null)
                  Text(
                    'Lat: ${position!.latitude.toStringAsFixed(4)}, Lon: ${position!.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  )
                else
                  const Text(
                    'Fetching location...',
                    style: TextStyle(
                        fontStyle: FontStyle.italic, color: Colors.white54),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturesGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _FeatureCard(
          title: 'Report Incident',
          iconSvg: CustomIcons.report,
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ReportIncidentScreen())),
        ),
        _FeatureCard(
          title: 'Live Map',
          iconSvg: CustomIcons.map,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const LiveMapScreen())),
        ),
        _FeatureCard(
          title: 'Safe Zones',
          iconSvg: CustomIcons.safeZone,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SafeZonesScreen())),
        ),
        _FeatureCard(
          title: 'Digital ID',
          iconSvg: CustomIcons.digitalId,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const DigitalIdScreen())),
        ),
        _FeatureCard(
          title: 'Notifications',
          iconSvg: CustomIcons.notifications,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen())),
        ),
        _FeatureCard(
          title: 'Help & Support',
          iconSvg: CustomIcons.help,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ChatScreen())),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String iconSvg;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.iconSvg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.string(
              iconSvg,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColor,
                BlendMode.srcIn,
              ),
              width: 48,
              height: 48,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

