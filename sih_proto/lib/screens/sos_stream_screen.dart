import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:sih_proto/providers/app_state.dart';
import 'package:sih_proto/services/supabase_config.dart';
import 'package:sih_proto/services/webrtc_service.dart';

class SOSStreamScreen extends StatefulWidget {
  final String alertId;
  const SOSStreamScreen({super.key, required this.alertId});

  @override
  State<SOSStreamScreen> createState() => _SOSStreamScreenState();
}

class _SOSStreamScreenState extends State<SOSStreamScreen> {
  late final WebRTCService _webRTCService;

  @override
  void initState() {
    super.initState();
    _webRTCService = WebRTCService(widget.alertId, SupabaseManager.client);
    _initialize();
  }

  Future<void> _initialize() async {
    await _webRTCService.initialize();
    await _webRTCService.startStream();
    setState(() {}); // To update the view with the local renderer
    await _webRTCService.createOffer();
  }
  
  @override
  void dispose() {
    _webRTCService.dispose();
    super.dispose();
  }

  void _stopSOS() {
    Provider.of<AppState>(context, listen: false).stopPanicAlert();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS ACTIVE - STREAMING'),
        backgroundColor: Colors.red,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: RTCVideoView(
              _webRTCService.localRenderer,
              mirror: true,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'You are live streaming your camera and location to the admin team. Help is on the way.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _stopSOS,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 16),
                  ),
                  child: const Text('STOP SOS'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

