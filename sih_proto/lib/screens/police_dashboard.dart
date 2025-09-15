import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String apiBaseUrl = "http://127.0.0.1:5000";

class Incident {
  final String id;
  final String title;
  final String description;
  final String severity;
  final String reportedAt;
  final String status;

  Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.reportedAt,
    required this.status,
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      severity: json['severity'] ?? 'Low',
      reportedAt: json['reportedAt'] ?? '',
      status: json['status'] ?? 'Open',
    );
  }
}

class PoliceDashboard extends StatefulWidget {
  const PoliceDashboard({super.key});

  @override
  State<PoliceDashboard> createState() => _PoliceDashboardState();
}

class _PoliceDashboardState extends State<PoliceDashboard> {
  List<Incident> incidents = [];
  late final SupabaseClient supabase;

  @override
  void initState() {
    super.initState();
    supabase = Supabase.instance.client;
    fetchIncidents();

    supabase.from('incidents').stream(primaryKey: ['id']).listen((
      List<Map<String, dynamic>> data,
    ) {
      setState(() {
        incidents = data.map((e) => Incident.fromJson(e)).toList();
      });
    });
  }

  Future<void> fetchIncidents() async {
    final response = await supabase.from('incidents').select().then((res) {
      setState(() {
        incidents = (res as List).map((e) => Incident.fromJson(e)).toList();
      });
    });
  }

  Future<void> updateIncidentStatus(String id, String status) async {
    final response = await supabase
        .from('incidents')
        .update({'status': status})
        .eq('id', id)
        .maybeSingle();
    if (response == null) {
      // Handle error if needed
    }
  }

  Widget build(BuildContext context) {
    final closedCases = incidents.where((i) => i.status == 'Closed').length;
    final activeUnits = incidents.where((i) => i.status == 'Active').length;

    return Scaffold(
      backgroundColor: const Color(0xFF1a202c),
      appBar: AppBar(
        title: const Text(
          'Police Dashboard',
          style: TextStyle(color: Colors.white),
        ),
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
          _buildInfoCard(
            'Reported Incidents',
            incidents.length.toString(),
            Icons.report,
            Colors.orange,
          ),
          const SizedBox(height: 20),
          _buildInfoCard('Active Units', activeUnits.toString(), Icons.local_police, Colors.blue),
          const SizedBox(height: 20),
          _buildInfoCard('Closed Cases', closedCases.toString(), Icons.check_circle, Colors.green),
          const SizedBox(height: 20),
          _buildIncidentList(),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
                Text(
                  title,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
        const Text(
          'Recent Incidents',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...incidents.map(
          (incident) => _buildIncidentTile(
            incident.id,
            incident.title,
            incident.description,
            incident.reportedAt,
            incident.severity,
            incident.status,
          ),
        ),
      ],
    );
  }

  Widget _buildIncidentTile(
    String id,
    String title,
    String description,
    String reportedAt,
    String severity,
    String status,
  ) {
    final Color severityColor = severity == 'High'
        ? Colors.red
        : severity == 'Medium'
            ? Colors.orange
            : Colors.green;

    IconData statusIcon;
    Color statusColor;
    if (status.toLowerCase() == 'critical') {
      statusIcon = Icons.warning_amber_rounded;
      statusColor = Colors.redAccent;
    } else if (status.toLowerCase() == 'closed') {
      statusIcon = Icons.check_circle;
      statusColor = Colors.green;
    } else if (status.toLowerCase() == 'active') {
      statusIcon = Icons.local_police;
      statusColor = Colors.blueAccent;
    } else {
      statusIcon = Icons.info;
      statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: const Color(0xFF2d3748),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        title: Row(
          children: [
            Icon(statusIcon, color: statusColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description, style: const TextStyle(color: Colors.white70)),
            Text(
              'Reported: $reportedAt',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            if (status != 'Closed')
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: ElevatedButton(
                  onPressed: () async {
                    await updateIncidentStatus(id, 'Closed');
                    fetchIncidents();
                  },
                  child: const Text('Close Case'),
                ),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: severityColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            severity,
            style: TextStyle(color: severityColor, fontWeight: FontWeight.bold),
          ),
        ),
        onTap: () {
          // Handle incident tap
        },
      ),
    );
  }
}
