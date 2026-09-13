import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirrors Firestore: users/{uid}/call_history/{callId}
/// {peerId, peerName, peerPhoto, type: audio|video,
///  direction: incoming|outgoing, status: completed|missed|rejected|failed,
///  startedAt, durationSec}
class CallModel {
  final String callId;
  final String peerId;
  final String peerName;
  final String peerPhoto;
  final String type; // 'audio' | 'video'
  final String direction; // 'incoming' | 'outgoing'
  final String status; // 'completed' | 'missed' | 'rejected' | 'failed'
  final DateTime startedAt;
  final int durationSec;

  const CallModel({
    required this.callId,
    required this.peerId,
    required this.peerName,
    this.peerPhoto = '',
    required this.type,
    required this.direction,
    required this.status,
    required this.startedAt,
    this.durationSec = 0,
  });

  bool get isVideo => type == 'video';
  bool get isMissed => status == 'missed';

  factory CallModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime started = DateTime.now();
    final raw = map['startedAt'];
    if (raw is Timestamp) {
      started = raw.toDate();
    } else if (raw is String) {
      started = DateTime.tryParse(raw) ?? DateTime.now();
    }
    return CallModel(
      callId: id,
      peerId: (map['peerId'] ?? '') as String,
      peerName: (map['peerName'] ?? 'Unknown') as String,
      peerPhoto: (map['peerPhoto'] ?? '') as String,
      type: (map['type'] ?? 'audio') as String,
      direction: (map['direction'] ?? 'outgoing') as String,
      status: (map['status'] ?? 'completed') as String,
      startedAt: started,
      durationSec: (map['durationSec'] ?? 0) as int,
    );
  }

  factory CallModel.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return CallModel.fromMap(doc.id, data);
  }

  Map<String, dynamic> toMap() {
    return {
      'peerId': peerId,
      'peerName': peerName,
      'peerPhoto': peerPhoto,
      'type': type,
      'direction': direction,
      'status': status,
      'startedAt': Timestamp.fromDate(startedAt),
      'durationSec': durationSec,
    };
  }
}

/// In-memory call session state machine:
/// calling -> ringing -> connected -> inCall -> ended
/// + terminal: rejected / missed / busy / failed / disconnected
class CallSession {
  final String callId;
  final String peerId;
  final String peerName;
  final String peerPhoto;
  final bool isVideo;
  final bool isOutgoing;
  final DateTime createdAt;

  const CallSession({
    required this.callId,
    required this.peerId,
    required this.peerName,
    this.peerPhoto = '',
    required this.isVideo,
    required this.isOutgoing,
    required this.createdAt,
  });
}
