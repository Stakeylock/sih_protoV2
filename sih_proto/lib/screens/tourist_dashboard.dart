import 'package:flutter/material.dart';

class TouristDashboard extends StatelessWidget {
  const TouristDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a202c),
      appBar: AppBar(
        title: const Text('Tourist Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2d3748),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              // Handle logout
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome, Tourist!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your safety is our priority. Here are some tools to help you.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildDashboardCard(
                    context,
                    icon: Icons.report_problem,
                    title: 'Report Incident',
                    color: Colors.red,
                    onTap: () {
                      // Navigate to report incident page
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    icon: Icons.map,
                    title: 'Live Map',
                    color: Colors.green,
                    onTap: () {
                      // Navigate to live map page
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    icon: Icons.local_hospital,
                    title: 'Safe Zones',
                    color: Colors.blue,
                    onTap: () {
                      // Navigate to safe zones page
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    icon: Icons.notifications,
                    title: 'Notifications',
                    color: Colors.orange,
                    onTap: () {
                      // Navigate to notifications page
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, {required IconData icon, required String title, required Color color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: const Color(0xFF2d3748),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
