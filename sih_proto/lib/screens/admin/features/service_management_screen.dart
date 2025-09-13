import 'package:flutter/material.dart';
import 'package:sih_proto/services/supabase_config.dart';

class ServiceManagementScreen extends StatefulWidget {
  const ServiceManagementScreen({super.key});

  @override
  State<ServiceManagementScreen> createState() => _ServiceManagementScreenState();
}

class _ServiceManagementScreenState extends State<ServiceManagementScreen> {
  final SupabaseManager _supabaseManager = SupabaseManager();
  late Future<List<VerifiedService>> _servicesFuture;

  @override
  void initState() {
    super.initState();
    _refreshServices();
  }

  void _refreshServices() {
    setState(() {
      _servicesFuture = _supabaseManager.getVerifiedServices();
    });
  }

  void _showAddEditDialog({VerifiedService? service}) {
    final isEditing = service != null;
    final nameController = TextEditingController(text: service?.name ?? '');
    final contactController = TextEditingController(text: service?.contact ?? '');
    String selectedType = service?.type ?? 'Transport';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2d3748),
        title: Text(isEditing ? 'Edit Service' : 'Add New Service', style: const TextStyle(color: Colors.white)),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Service Name'), style: const TextStyle(color: Colors.white)),
                  TextField(controller: contactController, decoration: const InputDecoration(labelText: 'Contact Info'), style: const TextStyle(color: Colors.white)),
                  DropdownButton<String>(
                    value: selectedType,
                    dropdownColor: const Color(0xFF2d3748),
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(value: 'Transport', child: Text('Transport')),
                      DropdownMenuItem(value: 'Medical', child: Text('Medical')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedType = value);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              // Note: You would need to add add/update methods to SupabaseManager for this to work.
              // For now, this just closes the dialog and refreshes the list.
              Navigator.of(context).pop();
              _refreshServices();
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
        title: const Text('Verified Services'),
        backgroundColor: const Color(0xFF2d3748),
      ),
      body: FutureBuilder<List<VerifiedService>>(
        future: _servicesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          final services = snapshot.data ?? [];
          return ListView.builder(
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return Card(
                color: const Color(0xFF2d3748),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(
                    service.type == 'Transport' ? Icons.local_taxi : Icons.local_hospital,
                    color: service.type == 'Transport' ? Colors.amberAccent : Colors.lightGreenAccent,
                  ),
                  title: Text(service.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(service.contact, style: const TextStyle(color: Colors.white54)),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blueAccent),
                    onPressed: () => _showAddEditDialog(service: service),
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
        label: const Text('Add Service'),
      ),
    );
  }
}

