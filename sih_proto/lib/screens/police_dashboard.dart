import 'package:flutter/material.dart';

class PoliceDashboard extends StatelessWidget {
  const PoliceDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a202c),
      appBar: AppBar(
        title: const Text('Police Dashboard', style: TextStyle(color: Colors.white)),
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
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildInfoCard('Reported Incidents', '12', Icons.report, Colors.orange),
          const SizedBox(height: 20),
          _buildIncidentList(),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: const Color(0xFF2d3748),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 5),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Incidents', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        // This would be a dynamic list from your database
        _buildIncidentTile('Theft at City Park', 'Reported 10 mins ago', 'High'),
        _buildIncidentTile('Suspicious Activity', 'Reported 30 mins ago', 'Medium'),
        _buildIncidentTile('Lost Tourist', 'Reported 1 hour ago', 'Low'),
      ],
    );
  }

  Widget _buildIncidentTile(String title, String subtitle, String severity) {
    final Color severityColor = severity == 'High' ? Colors.red : severity == 'Medium' ? Colors.orange : Colors.green;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: const Color(0xFF2d3748),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: severityColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(severity, style: TextStyle(color: severityColor, fontWeight: FontWeight.bold)),
        ),
        onTap: () {
          // Handle incident tap
        },
      ),
    );
  }
}
