import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/call_model.dart';

/// Reads/writes users/{uid}/call_history/{callId}
class HistoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _historyRef(String uid) => _db
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .collection(AppConstants.historySubcollection);

  Stream<List<CallModel>> historyStream(String uid) {
    return _historyRef(uid)
        .orderBy('startedAt', descending: true)
        .limit(100)
        .snapshots()
        .map((s) => s.docs.map(CallModel.fromDoc).toList());
  }

  Future<void> saveCall(String uid, CallModel call) async {
    await _historyRef(uid).doc(call.callId).set(call.toMap());
  }

  /// Persist history for BOTH sides of a call.
  /// [callerUid]/[calleeUid] with their respective directions.
  Future<void> saveCallForBoth({
    required String callId,
    required String callerUid,
    required String callerName,
    required String callerPhoto,
    required String calleeUid,
    required String calleeName,
    required String calleePhoto,
    required bool isVideo,
    required String callerStatus,
    required String calleeStatus,
    required DateTime startedAt,
    required int durationSec,
  }) async {
    final type = isVideo ? 'video' : 'audio';
    final outgoing = CallModel(
      callId: callId,
      peerId: calleeUid,
      peerName: calleeName,
      peerPhoto: calleePhoto,
      type: type,
      direction: 'outgoing',
      status: callerStatus,
      startedAt: startedAt,
      durationSec: durationSec,
    );
    final incoming = CallModel(
      callId: callId,
      peerId: callerUid,
      peerName: callerName,
      peerPhoto: callerPhoto,
      type: type,
      direction: 'incoming',
      status: calleeStatus,
      startedAt: startedAt,
      durationSec: durationSec,
    );
    await Future.wait([
      saveCall(callerUid, outgoing),
      saveCall(calleeUid, incoming),
    ]);
  }

  Future<void> clearHistory(String uid) async {
    final snap = await _historyRef(uid).get();
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }
}
