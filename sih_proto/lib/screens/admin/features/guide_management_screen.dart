import 'package:flutter/material.dart';

class GuideManagementScreen extends StatefulWidget {
  const GuideManagementScreen({super.key});

  @override
  State<GuideManagementScreen> createState() => _GuideManagementScreenState();
}

class Guide {
  final int id;
  String name;
  String languages;
  String specialization;

  Guide({
    required this.id,
    required this.name,
    required this.languages,
    required this.specialization,
  });
}

class Transport {
  final int id;
  String name;
  String type;
  int capacity;

  Transport({
    required this.id,
    required this.name,
    required this.type,
    required this.capacity,
  });
}

class _GuideManagementScreenState extends State<GuideManagementScreen> {
  List<Guide> _guides = [
    Guide(id: 1, name: 'John Doe', languages: 'English, Spanish', specialization: 'Historical Tours'),
    Guide(id: 2, name: 'Jane Smith', languages: 'English, French', specialization: 'Nature Tours'),
  ];
  List<Transport> _transports = [
    Transport(id: 1, name: 'Bus A', type: 'Bus', capacity: 40),
    Transport(id: 2, name: 'Van B', type: 'Van', capacity: 15),
    Transport(id: 3, name: 'Car C', type: 'Car', capacity: 4),
  ];

  @override
  void initState() {
    super.initState();
    _refreshGuides();
    _refreshTransports();
  }

  void _refreshGuides() {
    setState(() {});
  }

  void _refreshTransports() {
    setState(() {});
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
            onPressed: () {
              if (isEditing) {
                setState(() {
                  guide!.name = nameController.text;
                  guide.languages = langController.text;
                  guide.specialization = specController.text;
                });
              } else {
                setState(() {
                  final newId = _guides.isNotEmpty ? _guides.map((g) => g.id).reduce((a, b) => a > b ? a : b) + 1 : 1;
                  _guides.add(Guide(
                    id: newId,
                    name: nameController.text,
                    languages: langController.text,
                    specialization: specController.text,
                  ));
                });
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

  void _showAddEditTransportDialog({Transport? transport}) {
    final isEditing = transport != null;
    final nameController = TextEditingController(text: transport?.name ?? '');
    final typeController = TextEditingController(text: transport?.type ?? '');
    final capacityController = TextEditingController(text: transport?.capacity.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2d3748),
        title: Text(isEditing ? 'Edit Transport' : 'Add New Transport', style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name'), style: const TextStyle(color: Colors.white)),
              TextField(controller: typeController, decoration: const InputDecoration(labelText: 'Type'), style: const TextStyle(color: Colors.white)),
              TextField(controller: capacityController, decoration: const InputDecoration(labelText: 'Capacity'), keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final capacity = int.tryParse(capacityController.text) ?? 0;
              if (isEditing) {
                setState(() {
                  transport!.name = nameController.text;
                  transport.type = typeController.text;
                  transport.capacity = capacity;
                });
              } else {
                setState(() {
                  final newId = _transports.isNotEmpty ? _transports.map((t) => t.id).reduce((a, b) => a > b ? a : b) + 1 : 1;
                  _transports.add(Transport(
                    id: newId,
                    name: nameController.text,
                    type: typeController.text,
                    capacity: capacity,
                  ));
                });
              }
              Navigator.of(context).pop();
              _refreshTransports();
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
        title: const Text('Guide and Transport Management'),
        backgroundColor: const Color(0xFF2d3748),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              color: const Color(0xFF2d3748),
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Guides', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _guides.length,
                      itemBuilder: (context, index) {
                        final guide = _guides[index];
                        return Card(
                          color: const Color(0xFF2d3748),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: const Icon(Icons.badge_outlined, color: Colors.white70),
                            title: Text(guide.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text(guide.specialization, style: const TextStyle(color: Colors.white54)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent), onPressed: () => _showAddEditDialog(guide: guide)),
                                IconButton(icon: const Icon(Icons.delete_forever, color: Colors.redAccent), onPressed: () {
                                  setState(() {
                                    _guides.removeAt(index);
                                  });
                                  _refreshGuides();
                                }),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Card(
              color: const Color(0xFF2d3748),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Transports', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _transports.length,
                      itemBuilder: (context, index) {
                        final transport = _transports[index];
                        return Card(
                          color: const Color(0xFF2d3748),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: const Icon(Icons.directions_bus, color: Colors.white70),
                            title: Text(transport.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text('${transport.type} - Capacity: ${transport.capacity}', style: const TextStyle(color: Colors.white54)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent), onPressed: () => _showAddEditTransportDialog(transport: transport)),
                                IconButton(icon: const Icon(Icons.delete_forever, color: Colors.redAccent), onPressed: () {
                                  setState(() {
                                    _transports.removeAt(index);
                                  });
                                  _refreshTransports();
                                }),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: () => _showAddEditDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Guide'),
          ),
          const SizedBox(width: 16),
          FloatingActionButton.extended(
            onPressed: () => _showAddEditTransportDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Transport'),
          ),
        ],
      ),
    );
  }
}
