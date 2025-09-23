import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:sih_proto/providers/app_state.dart';
import 'package:sih_proto/services/supabase_config.dart';
import 'package:sih_proto/services/webrtc_service.dart';

class AdminSOSViewerScreen extends StatefulWidget {
  final Map<String, dynamic> alert;
  const AdminSOSViewerScreen({super.key, required this.alert});

  @override
  State<AdminSOSViewerScreen> createState() => _AdminSOSViewerScreenState();
}

class _AdminSOSViewerScreenState extends State<AdminSOSViewerScreen> {
  late final WebRTCService _webRTCService;

  @override
  void initState() {
    super.initState();
    _webRTCService = WebRTCService(widget.alert['id'], SupabaseManager.client);
    _initialize();
  }

  void _initialize() async {
    await _webRTCService.initialize();
    _webRTCService.listenForStream();
    // The service will automatically handle the incoming offer and send an answer
    // We need to listen to the renderer to update the UI when the stream arrives
    _webRTCService.remoteRenderer.addListener(() {
      if(mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _webRTCService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final touristId = widget.alert['tourist_id'];

    return Scaffold(
      appBar: AppBar(
        title: Text('SOS Alert: ${touristId.substring(0, 8)}'),
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.black,
              child: RTCVideoView(
                _webRTCService.remoteRenderer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              color: Theme.of(context).cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Emergency Type: ${widget.alert['emergency_type']?.toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  const Text('Actions:'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.local_police),
                        label: const Text('Forward to Police'),
                        onPressed: () {
                          appState.forwardAlert(widget.alert['id'], 'police');
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.local_hospital),
                        label: const Text('Forward to Medical'),
                        onPressed: () {
                           appState.forwardAlert(widget.alert['id'], 'medical');
                           Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      ),
                    ],
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () {
                       appState.updateAlertStatus(widget.alert['id'], 'resolved');
                       Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red, 
                      side: const BorderSide(color: Colors.red)
                    ),
                    child: const Text('Mark as Resolved & Stop Stream'),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

