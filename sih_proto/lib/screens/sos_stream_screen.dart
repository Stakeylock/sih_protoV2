import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/app_state.dart';
import '../services/webrtc_service.dart';

class SOSStreamScreen extends StatefulWidget {
  final String sosId;
  const SOSStreamScreen({super.key, required this.sosId});

  @override
  State<SOSStreamScreen> createState() => _SOSStreamScreenState();
}

class _SOSStreamScreenState extends State<SOSStreamScreen> {
  late final WebRTCService _webRTCService;
  bool _isServiceInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize the service with the specific SOS ID and Supabase client
    _webRTCService = WebRTCService(
      widget.sosId,
      Supabase.instance.client,
    );
    _initialize();
  }

  Future<void> _initialize() async {
    await _webRTCService.initialize();
    await _webRTCService.startStream();
    // After starting the local stream, create the offer to send to the admin
    await _webRTCService.createOffer(); 
    setState(() {
      _isServiceInitialized = true;
    });
  }

  @override
  void dispose() {
    _webRTCService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Live Stream'),
        backgroundColor: Colors.red,
        automaticallyImplyLeading: false, // Prevents user from going back easily
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              child: Center(
                child: _isServiceInitialized
                    ? RTCVideoView(_webRTCService.localRenderer)
                    : const CircularProgressIndicator(),
              ),
            ),
          ),
          _buildControls(context),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Live Feed Active',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Broadcasting your location and video to the emergency response team. Stay as safe as possible.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('Stop SOS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
            onPressed: () {
              // Use the AppState to properly end the alert
              Provider.of<AppState>(context, listen: false).stopPanicAlert();
              // Pop back to the dashboard
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

