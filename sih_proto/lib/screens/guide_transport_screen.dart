import 'package:flutter/material.dart';

class GuideTransportScreen extends StatelessWidget {
  const GuideTransportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> guidetransports = [
      {
        'type': 'bus',
        'title': 'Bus Route 1',
        'subtitle': 'Via kukatpally,jntu',
        'time': '10.15'
      },
      {
        'type': 'train',
        'title': 'Train Route 1',
        'subtitle': 'Express train',
        'time': '11.00'
      },
      {
        'type': 'metro',
        'title': 'Metro Line 2',
        'subtitle': 'Downtown to Uptown',
        'time': '11.30'
      },
      {
        'type': 'autorikshaw',
        'title': 'Auto',
        'subtitle': 'Auto Stand near Zone B',
        'time': '24/7'
      },
      {
        'type': 'bus',
        'title': 'Bus Route 2',
        'subtitle': 'Via kukatpally,jntu',
        'time': '10.15'
      },
    ];

    IconData getIcon(String type) {
      switch (type) {
        case 'bus':
          return Icons.directions_bus;
        case 'train':
          return Icons.train;
        case 'metro':
          return Icons.directions_subway;
        case 'autorikshaw':
          return Icons.directions_transit;
        default:
          return Icons.directions_transit;
      }
    }

    // Group the transport options by type
    final Map<String, List<Map<String, String>>> grouped = {
      'bus': [],
      'train': [],
      'metro': [],
      'autorikshaw': [],
    };
    for (final t in guidetransports) {
      if (grouped.containsKey(t['type'])) {
        grouped[t['type']]!.add(t);
      }
    }

    Widget buildSection(String type, String header) {
      final items = grouped[type] ?? [];
      if (items.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              header,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...items.map((guidetransport) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(
                    getIcon(guidetransport['type']!),
                    color: Theme.of(context).primaryColor,
                  ),
                  title: Text(
                    guidetransport['title']!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(guidetransport['subtitle']!),
                  trailing: Text(
                    guidetransport['time']!,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ),
              ))
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guide and Transportation'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          buildSection('bus', 'Buses'),
          buildSection('train', 'Trains'),
          buildSection('metro', 'Metro'),
          buildSection('autorikshaw', 'Auto'),
        ],
      ),
    );
  }
}