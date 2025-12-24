import 'package:flutter_webrtc/flutter_webrtc.dart';

class CallService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  
  // Coturn configurations (Oracle Cloud)
  final Map<String, dynamic> _config = {
    'iceServers': [
      {
        'urls': [
           'stun:stun.l.google.com:19302', // Fallback
           // 'turn:your-oracle-ip:3478' // Real TURN server
        ],
        // 'username': 'user',
        // 'credential': 'password'
      }
    ]
  };

  Future<void> startLocalStream() async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': true // Set false for voice-only
    });
  }

  Future<void> makeCall() async {
    _peerConnection = await createPeerConnection(_config);
    
    // Add local stream
    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    // Create Offer
    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    // Send offer via Signal Protocol / MQTT to recipient...
    // (Implementation required: wrap SDP in encryption and send via EncryptionService)
    print("SDP Offer created: ${offer.sdp}");
  }

  Future<void> receiveCall(RTCSessionDescription offer) async {
    _peerConnection = await createPeerConnection(_config);
    
    // Add local stream
    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    await _peerConnection!.setRemoteDescription(offer);
    
    // Create Answer
    RTCSessionDescription answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    // Send answer back...
  }
  
  void hangUp() {
    _localStream?.dispose();
    _peerConnection?.close();
  }

  MediaStream? get localStream => _localStream;
}
