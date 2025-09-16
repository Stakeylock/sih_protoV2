import 'package:flutter/material.dart';

class WomenChildSafetyScreen extends StatelessWidget {
  const WomenChildSafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a202c),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2d3748),
        title: const Text(
          "Women & Child Safety",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Active SOS Alerts",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Placeholder for alerts list
            Expanded(
              child: ListView(
                children: const [
                  Card(
                    color: Color(0xFF2d3748),
                    child: ListTile(
                      leading: Icon(Icons.warning, color: Colors.red),
                      title: Text(
                        "User123 needs help!",
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        "Location: Near Gate 2",
                        style: TextStyle(color: Colors.white70),
                      ),
                      trailing: Text(
                        "Active",
                        style: TextStyle(color: Colors.orangeAccent),
                      ),
                    ),
                  ),
                  Card(
                    color: Color(0xFF2d3748),
                    child: ListTile(
                      leading: Icon(Icons.warning, color: Colors.red),
                      title: Text(
                        "User456 reported harassment",
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        "Location: Zone B",
                        style: TextStyle(color: Colors.white70),
                      ),
                      trailing: Text(
                        "Resolved",
                        style: TextStyle(color: Colors.greenAccent),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
