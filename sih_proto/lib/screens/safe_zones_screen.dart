import 'package:flutter/material.dart';
import 'package:sih_proto/services/database_service.dart';

class SafeZonesScreen extends StatelessWidget {
  const SafeZonesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safe Zones'),
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: dbService.getSafeZones(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No safe zones found.'));
          }

          final safeZones = snapshot.data!;

          return ListView.builder(
            itemCount: safeZones.length,
            itemBuilder: (context, index) {
              final zone = safeZones[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.verified_user,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: Text(
                    zone['name'] ?? 'Unnamed Zone',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(zone['description'] ?? 'No description.'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

