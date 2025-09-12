import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // This is a placeholder. In a real app, you would fetch notifications.
    final List<Map<String, String>> notifications = [
      {
        'title': 'Safety Alert: High-Risk Zone',
        'subtitle': 'You are approaching a restricted area. Proceed with caution.',
        'time': '5m ago'
      },
      {
        'title': 'New Safe Zone Added',
        'subtitle': 'A new police booth has been set up near your location.',
        'time': '2h ago'
      },
      {
        'title': 'Welcome to the Northeast!',
        'subtitle': 'We wish you a safe and pleasant journey.',
        'time': '1d ago'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return Card(
             margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            child: ListTile(
              leading: Icon(
                Icons.notifications_active,
                color: Theme.of(context).primaryColor,
              ),
              title: Text(
                notification['title']!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(notification['subtitle']!),
              trailing: Text(
                notification['time']!,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ),
          );
        },
      ),
    );
  }
}

