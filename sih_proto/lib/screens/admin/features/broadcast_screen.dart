import 'package:flutter/material.dart';
import 'package:sih_proto/services/supabase_config.dart';

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  final SupabaseManager _supabaseManager = SupabaseManager();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<SafetyZone> _safetyZones = [];
  int? _selectedZoneId;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _fetchZones();
  }

  Future<void> _fetchZones() async {
    setState(() => _isLoading = true);
    try {
      final zones = await _supabaseManager.getSafetyZones();
      if (mounted) {
        setState(() {
          _safetyZones = zones;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load safety zones: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendBroadcast() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedZoneId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a target zone.'), backgroundColor: Colors.orange),
        );
        return;
      }

      setState(() => _isSending = true);

      try {
        await _supabaseManager.sendBroadcastNotification(
          title: _titleController.text,
          message: _messageController.text,
          zoneId: _selectedZoneId!,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Broadcast sent successfully!'), backgroundColor: Colors.green),
          );
          _titleController.clear();
          _messageController.clear();
          setState(() => _selectedZoneId = null);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send broadcast: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSending = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Broadcast Notification'),
      ),
      backgroundColor: const Color(0xFF1a202c),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Compose Message',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Send an alert to all tourists inside a specific safety zone.',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 24),

                    // Dropdown for selecting zone
                    DropdownButtonFormField<int>(
                      value: _selectedZoneId,
                      dropdownColor: const Color(0xFF2d3748),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Target Safety Zone',
                        labelStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: _safetyZones.map((zone) {
                        return DropdownMenuItem<int>(
                          value: zone.id,
                          child: Text(zone.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedZoneId = value);
                      },
                      validator: (value) => value == null ? 'Please select a zone' : null,
                    ),
                    const SizedBox(height: 16),

                    // Title Field
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Notification Title',
                        labelStyle: TextStyle(color: Colors.grey),
                         border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
                    ),
                    const SizedBox(height: 16),

                    // Message Field
                    TextFormField(
                      controller: _messageController,
                       style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        labelStyle: TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                       maxLines: 5,
                      validator: (value) => value == null || value.isEmpty ? 'Please enter a message' : null,
                    ),
                    const SizedBox(height: 24),

                    // Send Button
                    ElevatedButton.icon(
                      onPressed: _isSending ? null : _sendBroadcast,
                      icon: _isSending
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send_rounded),
                      label: Text(_isSending ? 'Sending...' : 'Send Broadcast'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

