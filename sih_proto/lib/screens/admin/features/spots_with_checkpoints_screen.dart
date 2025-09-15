// lib/screens/admin/features/spots_with_checkpoints_screen.dart
import 'package:flutter/material.dart';
import 'package:sih_proto/services/database_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SpotsWithCheckpointsScreen extends StatefulWidget {
  const SpotsWithCheckpointsScreen({super.key});

  @override
  State<SpotsWithCheckpointsScreen> createState() => _SpotsWithCheckpointsScreenState();
}

class _SpotsWithCheckpointsScreenState extends State<SpotsWithCheckpointsScreen> {
  final DatabaseService _db = DatabaseService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _db.getSpotsWithCheckpoints();
  }

  void _showCheckpointQr({
    required String checkpointId,
    required String spotName,
    required num? checkpointNumber,
  }) {
    // Encode as a deep link or just the UUID; deep link is recommended
    final data = 'app://checkpoint/$checkpointId';

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2d3748),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (spotName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    spotName,
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (checkpointNumber != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Checkpoint $checkpointNumber',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white, // high contrast for scanners
                child: QrImageView(
                  data: data,
                  version: QrVersions.auto,
                  size: 220,
                  gapless: true,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                checkpointId,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'Scan to identify this checkpoint',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a202c),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2d3748),
        elevation: 0,
        title: const Text('Spots & Checkpoints'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Failed to load spots: ${snap.error}',
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final spots = snap.data ?? const <Map<String, dynamic>>[];
          if (spots.isEmpty) {
            return const Center(
              child: Text('No tourist spots found.', style: TextStyle(color: Colors.white70)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: spots.length,
            itemBuilder: (context, index) {
              final spot = spots[index];
              final cps = (spot['tourist_spot_checkpoints'] as List?)
                      ?.cast<Map<String, dynamic>>() ??
                  const <Map<String, dynamic>>[];

              return Card(
                color: const Color(0xFF2d3748),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    iconColor: Colors.white70,
                    collapsedIconColor: Colors.white70,
                    title: Text(
                      (spot['spot_name'] ?? 'Unnamed spot') as String,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      (spot['spot_location'] ?? '') as String,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.place, size: 16, color: Colors.white54),
                          const SizedBox(width: 6),
                          Text(
                            'Checkpoints: ${spot['no_of_checkpoints'] ?? cps.length}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (cps.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text('No checkpoints added.', style: TextStyle(color: Colors.white54)),
                        )
                      else
                        ...cps.map((c) {
                          final number = c['checkpoint_number'] as num?;
                          final created = c['created_at'];
                          final createdStr = created != null
                              ? DateTime.tryParse(created.toString())?.toLocal().toString() ?? ''
                              : '';
                          final id = c['checkpoint_id']?.toString() ?? '';

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.flag, color: Colors.orangeAccent),
                            title: Text(
                              number != null ? 'Checkpoint $number' : 'Checkpoint',
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              createdStr,
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                            trailing: const Icon(Icons.qr_code_2, color: Colors.white70),
                            onTap: id.isEmpty
                                ? null
                                : () => _showCheckpointQr(
                                      checkpointId: id,
                                      spotName: (spot['spot_name'] ?? '') as String? ?? '',
                                      checkpointNumber: number,
                                    ),
                          );
                        }),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
