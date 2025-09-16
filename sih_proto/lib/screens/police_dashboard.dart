import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sih_proto/screens/admin/features/women_child_safety_screen.dart';

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
      id: json['id']?.toString() ?? 'N/A',
      title: json['title']?.toString() ?? 'No Title',
      description: json['description']?.toString() ?? 'No Description',
      severity: json['severity']?.toString() ?? 'Unknown',
      reportedAt: json['reportedAt']?.toString() ?? json['reported_at']?.toString() ?? 'Unknown Time',
      status: json['status']?.toString() ?? 'Open',
    );
  }
}

class PoliceDashboard extends StatefulWidget {
  const PoliceDashboard({super.key});

  @override
  State<PoliceDashboard> createState() => _PoliceDashboardState();
}

class _PoliceDashboardState extends State<PoliceDashboard> {
  bool _isLoading = true;
  String _selectedStatusFilter = 'All';
  List<Incident> _incidents = [];
  late final SupabaseClient _supabase;
  RealtimeChannel? _incidentChannel;

  final List<String> _statusFilters = const ['All', 'Open', 'Active', 'Critical', 'Closed'];

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _fetchIncidents();

    _incidentChannel = _supabase.channel('public:incidents');
    _incidentChannel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'incidents',
      callback: (payload) {
        _fetchIncidents();
      },
    ).subscribe();
  }

  @override
  void dispose() {
    if (_incidentChannel != null) {
      _supabase.removeChannel(_incidentChannel!);
    }
    super.dispose();
  }

  Future<void> _fetchIncidents() async {
    if (_incidents.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }

    final response = await _supabase.from('incidents').select().order('id', ascending: false);

    if (mounted) {
      setState(() {
        _incidents = (response as List).map((e) => Incident.fromJson(e)).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateIncidentStatus(String id, String status) async {
    final incidentIndex = _incidents.indexWhere((i) => i.id == id);
    if (incidentIndex == -1) {
      return;
    }
    final originalIncident = _incidents[incidentIndex];

    final updatedIncident = Incident(
      id: originalIncident.id,
      title: originalIncident.title,
      description: originalIncident.description,
      severity: originalIncident.severity,
      reportedAt: originalIncident.reportedAt,
      status: status,
    );

    setState(() {
      _incidents[incidentIndex] = updatedIncident;
    });

    try {
      await _supabase.from('incidents').update({'status': status}).eq('id', id);
    } catch (error) {
      if (mounted) {
        setState(() {
          _incidents[incidentIndex] = originalIncident;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Could not close case. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  List<Incident> get _filteredIncidents {
    if (_selectedStatusFilter == 'All') {
      return _incidents;
    }
    return _incidents.where((i) => i.status == _selectedStatusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final closedCases = _incidents.where((i) => i.status == 'Closed').length;
    final activeUnits = _incidents.where((i) => i.status == 'Active').length;

    return Scaffold(
      backgroundColor: const Color(0xFF1a202c),
      appBar: AppBar(
        title: const Text('Police Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2d3748),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchIncidents,
        color: Colors.white,
        backgroundColor: const Color(0xFF2d3748),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                   //New Women & Child Support button
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const WomenChildSafetyScreen()),
                      );
                    },
                    child: _buildInfoCard(
                      'Women & Child Support',
                      '',
                      Icons.sos_rounded,
                      Colors.pinkAccent,
                      centerText: true, // 👈 only this card centers its text
                    ),
                  ),

                  _buildInfoCard('Reported Incidents', _incidents.length.toString(), Icons.report, Colors.orange),
                  const SizedBox(height: 20),
                  _buildInfoCard('Active Units', activeUnits.toString(), Icons.local_police, Colors.blue),
                  const SizedBox(height: 20),
                  _buildInfoCard('Closed Cases', closedCases.toString(), Icons.check_circle, Colors.green),
                  const SizedBox(height: 30),
                  _buildFilterChips(),
                  const SizedBox(height: 10),
                  _buildIncidentList(),
                ],
              ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _statusFilters.map((status) {
          final isSelected = _selectedStatusFilter == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(status),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedStatusFilter = status;
                });
              },
              backgroundColor: const Color(0xFF2d3748),
              selectedColor: Colors.blueAccent,
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
              checkmarkColor: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildIncidentList() {
    final incidentsToDisplay = _filteredIncidents;

    if (incidentsToDisplay.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No incidents found for this filter.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Showing ${incidentsToDisplay.length} Incidents',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ...incidentsToDisplay.map((incident) => _buildIncidentTile(incident)),
      ],
    );
  }

  Widget _buildIncidentTile(Incident incident) {
    final Color severityColor = incident.severity == 'High'
        ? Colors.red
        : incident.severity == 'Medium'
            ? Colors.orange
            : Colors.green;

    IconData statusIcon;
    Color statusColor;
    switch (incident.status.toLowerCase()) {
      case 'critical':
        statusIcon = Icons.warning_amber_rounded;
        statusColor = Colors.redAccent;
        break;
      case 'closed':
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        break;
      case 'active':
        statusIcon = Icons.local_police;
        statusColor = Colors.blueAccent;
        break;
      default:
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
                incident.title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(incident.description, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Text('Reported: ${incident.reportedAt}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              if (incident.status != 'Closed')
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: ElevatedButton(
                    onPressed: () => _updateIncidentStatus(incident.id, 'Closed'),
                    child: const Text('Close Case'),
                  ),
                ),
            ],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: severityColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            incident.severity,
            style: TextStyle(color: severityColor, fontWeight: FontWeight.bold),
          ),
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tapped on incident: ${incident.title}'),
              backgroundColor: Colors.blueAccent,
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color, {bool centerText = false}) {
  return Card(
    color: const Color(0xFF2d3748),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // align vertically
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: centerText ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 16)),
              if (value.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
        ],
      ),
    ),
  );
 }
}
