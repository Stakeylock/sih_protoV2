import 'package:flutter/material.dart';
import 'package:sih_proto/services/supabase_config.dart';

class GuideManagementScreen extends StatefulWidget {
  const GuideManagementScreen({super.key});

  @override
  State<GuideManagementScreen> createState() => _GuideManagementScreenState();
}

class _GuideManagementScreenState extends State<GuideManagementScreen> {
  final SupabaseManager _supabaseManager = SupabaseManager();
  late Future<List<Guide>> _guidesFuture;

  @override
  void initState() {
    super.initState();
    _refreshGuides();
  }

  void _refreshGuides() {
    setState(() {
      _guidesFuture = _supabaseManager.getGuides();
    });
  }

  void _showAddEditDialog({Guide? guide}) {
    final isEditing = guide != null;
    final nameController = TextEditingController(text: guide?.name ?? '');
    final langController = TextEditingController(text: guide?.languages ?? '');
    final specController = TextEditingController(text: guide?.specialization ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2d3748),
        title: Text(isEditing ? 'Edit Guide' : 'Add New Guide', style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name'), style: const TextStyle(color: Colors.white)),
              TextField(controller: langController, decoration: const InputDecoration(labelText: 'Languages'), style: const TextStyle(color: Colors.white)),
              TextField(controller: specController, decoration: const InputDecoration(labelText: 'Specialization'), style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (isEditing) {
                final updatedGuide = Guide(
                  id: guide!.id,
                  name: nameController.text,
                  languages: langController.text,
                  specialization: specController.text,
                );
                await _supabaseManager.updateGuide(updatedGuide);
              } else {
                await _supabaseManager.addGuide(nameController.text, langController.text, specController.text);
              }
              Navigator.of(context).pop();
              _refreshGuides();
            },
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a202c),
      appBar: AppBar(
        title: const Text('Guide Management'),
        backgroundColor: const Color(0xFF2d3748),
      ),
      body: FutureBuilder<List<Guide>>(
        future: _guidesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          final guides = snapshot.data ?? [];
          return ListView.builder(
            itemCount: guides.length,
            itemBuilder: (context, index) {
              final guide = guides[index];
              return Card(
                color: const Color(0xFF2d3748),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.badge_outlined, color: Colors.white70),
                  title: Text(guide.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(guide.specialization, style: const TextStyle(color: Colors.white54)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent), onPressed: () => _showAddEditDialog(guide: guide)),
                      IconButton(icon: const Icon(Icons.delete_forever, color: Colors.redAccent), onPressed: () => _supabaseManager.deleteGuide(guide.id).then((_) => _refreshGuides())),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Guide'),
      ),
    );
  }
}

