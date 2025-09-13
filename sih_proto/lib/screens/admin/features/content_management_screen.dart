import 'package:flutter/material.dart';
import 'package:sih_proto/services/supabase_config.dart';

class ContentManagementScreen extends StatelessWidget {
  const ContentManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF1a202c),
        appBar: AppBar(
          title: const Text('Content Management'),
          backgroundColor: const Color(0xFF2d3748),
          bottom: const TabBar(
            indicatorColor: Colors.blueAccent,
            tabs: [
              Tab(text: 'Contests & Quizzes'),
              Tab(text: 'Local Events'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ContentListView(type: 'contest'),
            _ContentListView(type: 'event'),
          ],
        ),
      ),
    );
  }
}

class _ContentListView extends StatelessWidget {
  final String type;
  const _ContentListView({required this.type});

  @override
  Widget build(BuildContext context) {
    final SupabaseManager supabaseManager = SupabaseManager();
    return FutureBuilder<List<ContentItem>>(
      future: supabaseManager.getContentItems(type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(child: Text('No ${type}s found.', style: const TextStyle(color: Colors.white70)));
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              color: const Color(0xFF2d3748),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(item.title, style: const TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.edit, color: Colors.blueAccent),
              ),
            );
          },
        );
      },
    );
  }
}
