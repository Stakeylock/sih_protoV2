import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  RealtimeChannel? _channel;
  final String _alertId;
  final SupabaseClient _supabaseClient;

  RTCVideoRenderer get localRenderer => _localRenderer;
  RTCVideoRenderer get remoteRenderer => _remoteRenderer;

  WebRTCService(this._alertId, this._supabaseClient);

  Future<void> initialize() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    _peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    });

    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null) {
        _sendSignalingMessage({'candidate': candidate.toMap()});
      }
    };

    _peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.track.kind == 'video' && event.streams.isNotEmpty) {
        _remoteRenderer.srcObject = event.streams[0];
      }
    };
  }

  Future<void> startStream() async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      'video': true,
      'audio': true,
    });
    
    _localRenderer.srcObject = _localStream;
    
    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });
    
    _connectToSignaling();
  }

  void listenForStream() {
    _connectToSignaling();
  }

  void _connectToSignaling() {
    _channel = _supabaseClient.channel('webrtc:$_alertId');
    _channel!
        .onBroadcast(
          event: 'signal',
          callback: (payload) => _handleSignalingMessage(payload),
        )
        .subscribe();
  }

  Future<void> _handleSignalingMessage(Map payload) async {
    // The payload from onBroadcast is already a map, no need to decode
    final data = payload['data'];
    if (data == null || data is! Map) return;

    if (data['offer'] != null) {
      await _peerConnection?.setRemoteDescription(
        RTCSessionDescription(data['offer']['sdp'], data['offer']['type'])
      );
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);
      _sendSignalingMessage({'answer': answer.toMap()});
    }

    if (data['answer'] != null) {
      await _peerConnection?.setRemoteDescription(
        RTCSessionDescription(data['answer']['sdp'], data['answer']['type'])
      );
    }

    if (data['candidate'] != null) {
      await _peerConnection?.addCandidate(RTCIceCandidate(
        data['candidate']['candidate'],
        data['candidate']['sdpMid'],
        data['candidate']['sdpMLineIndex']
      ));
    }
  }

  void _sendSignalingMessage(Map data) {
    _channel?.sendBroadcastMessage(
      event: 'signal',
      payload: {'data': data},
    );
  }

  Future<void> createOffer() async {
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    _sendSignalingMessage({'offer': offer.toMap()});
  }

  void dispose() {
    _localStream?.getTracks().forEach((track) => track.stop());
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _peerConnection?.close();
    if (_channel != null) {
      _supabaseClient.removeChannel(_channel!);
    }
  }
}
