import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import '../models/call_model.dart';
import '../models/user_model.dart';
import '../services/calling_service.dart';
import '../services/history_service.dart';

/// Call state machine:
/// idle -> calling -> ringing -> connected -> inCall -> ended
/// terminal failures: rejected / missed / busy / failed / disconnected
/// Timer starts on connected.
class CallProvider extends ChangeNotifier {
  final HistoryService _history = HistoryService();
  final CallingService _calling = CallingService.instance;

  CallSession? _currentCall;
  String _callStatus = 'idle';
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = true;
  bool _isFrontCamera = true;
  int _duration = 0;

  Timer? _timer;
  DateTime? _connectedAt;
  DateTime? _sessionStartedAt;
  bool _callbacksWired = false;

  String? _localUid;
  String? _localName;
  String _localPhoto = '';

  CallSession? get currentCall => _currentCall;
  String get callStatus => _callStatus;
  bool get isMuted => _isMuted;
  bool get isCameraOff => _isCameraOff;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get isFrontCamera => _isFrontCamera;
  int get duration => _duration;
  bool get inCall => _currentCall != null &&
      (_callStatus == 'calling' ||
          _callStatus == 'ringing' ||
          _callStatus == 'connected' ||
          _callStatus == 'inCall');

  /// Must be called once after login with the signed-in user.
  void bindLocalUser(UserModel user) {
    _localUid = user.uid;
    _localName = user.name;
    _localPhoto = user.photoUrl;
    _wireCallbacks();
  }

  void _wireCallbacks() {
    if (_callbacksWired) return;
    _callbacksWired = true;

    _calling.onIncomingReceived = (session) {
      // Busy: already in another call -> auto reject.
      if (_currentCall != null) {
        _calling.rejectInvitation(customData: 'busy');
        return;
      }
      _currentCall = session;
      _sessionStartedAt = session.createdAt;
      _callStatus = 'ringing';
      _resetMediaFlags(video: session.isVideo);
      notifyListeners();
    };
    _calling.onIncomingCanceled = (callID) async {
      if (_currentCall?.callId != callID) return;
      await _persistHistory(
        callerStatus: 'failed',
        calleeStatus: 'missed',
        durationSec: 0,
      );
      _setTerminated('missed');
    };
    _calling.onIncomingTimeout = (callID) async {
      if (_currentCall?.callId != callID) return;
      await _persistHistory(
        callerStatus: 'failed',
        calleeStatus: 'missed',
        durationSec: 0,
      );
      _setTerminated('missed');
    };
    _calling.onOutgoingAccepted = (callID, callee) {
      if (_currentCall?.callId != callID) return;
      _markConnected();
    };
    _calling.onOutgoingDeclined = (callID, callee, customData) async {
      if (_currentCall?.callId != callID) return;
      await _persistHistory(
        callerStatus: 'rejected',
        calleeStatus: 'rejected',
        durationSec: 0,
      );
      _setTerminated('rejected');
    };
    _calling.onOutgoingBusy = (callID, callee, customData) async {
      if (_currentCall?.callId != callID) return;
      await _persistHistory(
        callerStatus: 'failed',
        calleeStatus: 'missed',
        durationSec: 0,
      );
      _setTerminated('busy');
    };
    _calling.onOutgoingTimeout = (callID, callees, isVideo) async {
      if (_currentCall?.callId != callID) return;
      await _persistHistory(
        callerStatus: 'failed',
        calleeStatus: 'missed',
        durationSec: 0,
      );
      _setTerminated('failed');
    };
  }

  void _resetMediaFlags({required bool video}) {
    _isMuted = false;
    _isCameraOff = false;
    _isSpeakerOn = true;
    _isFrontCamera = true;
    _duration = 0;
    _connectedAt = null;
    _timer?.cancel();
  }

  /// Outgoing call. Returns callID on success, null on failure.
  /// UI should check permissions BEFORE calling this, then navigate
  /// to /audio-call or /video-call on non-null.
  Future<String?> startCall({
    required UserModel peer,
    required bool isVideo,
  }) async {
    if (_localUid == null) {
      _callStatus = 'failed';
      notifyListeners();
      throw Exception('Not logged in');
    }
    if (_currentCall != null) {
      throw Exception('Already in a call');
    }
    _resetMediaFlags(video: isVideo);
    final session = CallSession(
      callId: '',
      peerId: peer.uid,
      peerName: peer.name,
      peerPhoto: peer.photoUrl,
      isVideo: isVideo,
      isOutgoing: true,
      createdAt: DateTime.now(),
    );
    _currentCall = session;
    _sessionStartedAt = session.createdAt;
    _callStatus = 'calling';
    notifyListeners();

    try {
      // Caller-side guard: (re)connect ZIM signaling before sending.
      // ZIM login completes asynchronously after init and can drop when
      // the app was backgrounded — never assume a past init is enough.
      if (!_calling.isInitialized && _localUid != null) {
        try {
          await _calling.initZego(
            uid: _localUid!,
            userName: _localName ?? 'User',
          );
        } catch (_) {}
      }
      if (!_calling.isSignalingConnected) {
        final ok = await _calling.ensureSignalingConnected();
        if (!ok) {
          final reconnected = await _calling.reconnectSignaling();
          if (!reconnected) throw const SignalingOfflineException();
        }
      }
      final callID = await _calling.sendCallInvitation(
        callerId: UserModel(
                uid: _localUid!, name: _localName ?? '', email: '')
            .zegoUserId,
        callerName: _localName ?? 'Unknown',
        callerPhoto: _localPhoto,
        calleeId: peer.zegoUserId,
        calleeName: peer.name,
        isVideo: isVideo,
      );
      _currentCall = CallSession(
        callId: callID,
        peerId: peer.uid,
        peerName: peer.name,
        peerPhoto: peer.photoUrl,
        isVideo: isVideo,
        isOutgoing: true,
        createdAt: session.createdAt,
      );
      _callStatus = 'ringing';
      notifyListeners();
      return callID;
    } catch (e) {
      // Invitation failed (offline/busy) — persist as failed/missed.
      final failId =
          'call_${DateTime.now().millisecondsSinceEpoch}_failed';
      await _persistHistoryWithIds(
        callId: failId,
        peerUid: peer.uid,
        peerName: peer.name,
        peerPhoto: peer.photoUrl,
        isVideo: isVideo,
        isOutgoing: true,
        callerStatus: 'failed',
        calleeStatus: 'missed',
        durationSec: 0,
        startedAt: session.createdAt,
      );
      _currentCall = null;
      _callStatus = 'failed';
      notifyListeners();
      rethrow;
    }
  }

  /// Callee accepts from Incoming screen. UI navigates to call screen after.
  Future<void> accept() async {
    if (_currentCall == null) return;
    await _calling.acceptInvitation();
    _markConnected();
  }

  /// Callee declines from Incoming screen.
  Future<void> reject() async {
    if (_currentCall == null) return;
    await _calling.rejectInvitation();
    await _persistHistory(
      callerStatus: 'rejected',
      calleeStatus: 'rejected',
      durationSec: 0,
    );
    _setTerminated('rejected');
  }

  /// Caller cancels outgoing call while ringing (or any side hangs up
  /// before connect). Distinguished from [end] which is after connect.
  Future<void> cancelOutgoing() async {
    if (_currentCall == null) return;
    if (_currentCall!.isOutgoing) {
      try {
        await _calling.cancelInvitation(
          callees: [ZegoCallUser(_peerZegoId(), _currentCall!.peerName)],
        );
      } catch (_) {}
      await _persistHistory(
        callerStatus: 'failed',
        calleeStatus: 'missed',
        durationSec: 0,
      );
    }
    _setTerminated('ended');
  }

  /// Hang up an active/connected call. Called from End button or
  /// Zego onCallEnd. Saves history for BOTH users.
  Future<void> end() async {
    if (_currentCall == null) {
      _callStatus = 'idle';
      notifyListeners();
      return;
    }
    final bool wasConnected =
        _connectedAt != null || _duration > 0 || _callStatus == 'connected' || _callStatus == 'inCall';
    if (wasConnected) {
      await _persistHistory(
        callerStatus: 'completed',
        calleeStatus: 'completed',
        durationSec: _duration,
      );
      _setTerminated('ended');
    } else {
      // Ended before connect without explicit reject/cancel path.
      if (_currentCall!.isOutgoing) {
        try {
          await _calling.cancelInvitation(
            callees: [ZegoCallUser(_peerZegoId(), _currentCall!.peerName)],
          );
        } catch (_) {}
        await _persistHistory(
          callerStatus: 'failed',
          calleeStatus: 'missed',
          durationSec: 0,
        );
      } else {
        await _persistHistory(
          callerStatus: 'failed',
          calleeStatus: 'missed',
          durationSec: 0,
        );
      }
      _setTerminated('ended');
    }
  }

  /// Zego room event: remote user joined / call connected.
  void markConnected() => _markConnected();

  void _markConnected() {
    if (_currentCall == null) return;
    if (_connectedAt != null) return;
    _connectedAt = DateTime.now();
    _callStatus = 'connected';
    notifyListeners();
    _callStatus = 'inCall';
    notifyListeners();
    _startTimer();
  }

  /// Remote hung up / network drop reported by Zego.
  Future<void> markDisconnected() async {
    if (_currentCall == null) return;
    final bool wasConnected = _connectedAt != null;
    await _persistHistory(
      callerStatus: wasConnected ? 'completed' : 'failed',
      calleeStatus: wasConnected ? 'completed' : 'missed',
      durationSec: _duration,
    );
    _setTerminated('disconnected');
  }

  // ---- Media controls (wired to ZegoUIKit + local state) ----

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    notifyListeners();
    try {
      ZegoUIKit().turnMicrophoneOn(!_isMuted);
    } catch (_) {}
  }

  Future<void> toggleCamera() async {
    _isCameraOff = !_isCameraOff;
    notifyListeners();
    try {
      ZegoUIKit().turnCameraOn(!_isCameraOff);
    } catch (_) {}
  }

  /// Switch front/rear. Zego toolbar also offers this; provider tracks intent.
  Future<void> switchCamera() async {
    _isFrontCamera = !_isFrontCamera;
    notifyListeners();
    try {
      // zego_uikit exposes useFrontFacingCamera on some versions;
      // fall back silently if unavailable — built-in toolbar still switches.
      (ZegoUIKit() as dynamic).useFrontFacingCamera?.call(_isFrontCamera);
    } catch (_) {}
  }

  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    notifyListeners();
    try {
      ZegoUIKit().setAudioOutputToSpeaker(_isSpeakerOn);
    } catch (_) {}
  }

  void clearTerminated() {
    if (_callStatus == 'ended' ||
        _callStatus == 'rejected' ||
        _callStatus == 'missed' ||
        _callStatus == 'failed' ||
        _callStatus == 'busy' ||
        _callStatus == 'disconnected') {
      _currentCall = null;
      _callStatus = 'idle';
      notifyListeners();
    }
  }

  // ---- internals ----

  String _peerZegoId() {
    final id = (_currentCall?.peerId ?? '')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    return id.isEmpty ? 'unknown' : id;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _duration++;
      notifyListeners();
    });
  }

  void _setTerminated(String status) {
    _timer?.cancel();
    _callStatus = status;
    notifyListeners();
    // Keep session briefly so UI can read final status, then idle.
    Future.delayed(const Duration(seconds: 2), () {
      if (_callStatus == status) {
        _currentCall = null;
        if (_callStatus == status) {
          _callStatus = 'idle';
          _duration = 0;
          _connectedAt = null;
          notifyListeners();
        }
      }
    });
  }

  Future<void> _persistHistory({
    required String callerStatus,
    required String calleeStatus,
    required int durationSec,
  }) async {
    final call = _currentCall;
    final local = _localUid;
    if (call == null || local == null) return;
    final started = _sessionStartedAt ?? call.createdAt;
    try {
      if (call.isOutgoing) {
        await _history.saveCallForBoth(
          callId: call.callId.isEmpty
              ? 'call_${started.millisecondsSinceEpoch}'
              : call.callId,
          callerUid: local,
          callerName: _localName ?? 'Me',
          callerPhoto: _localPhoto,
          calleeUid: call.peerId,
          calleeName: call.peerName,
          calleePhoto: call.peerPhoto,
          isVideo: call.isVideo,
          callerStatus: callerStatus,
          calleeStatus: calleeStatus,
          startedAt: started,
          durationSec: durationSec,
        );
      } else {
        await _history.saveCallForBoth(
          callId: call.callId.isEmpty
              ? 'call_${started.millisecondsSinceEpoch}'
              : call.callId,
          callerUid: call.peerId,
          callerName: call.peerName,
          callerPhoto: call.peerPhoto,
          calleeUid: local,
          calleeName: _localName ?? 'Me',
          calleePhoto: _localPhoto,
          isVideo: call.isVideo,
          callerStatus: callerStatus,
          calleeStatus: calleeStatus,
          startedAt: started,
          durationSec: durationSec,
        );
      }
    } catch (_) {}
  }

  Future<void> _persistHistoryWithIds({
    required String callId,
    required String peerUid,
    required String peerName,
    required String peerPhoto,
    required bool isVideo,
    required bool isOutgoing,
    required String callerStatus,
    required String calleeStatus,
    required int durationSec,
    required DateTime startedAt,
  }) async {
    final local = _localUid;
    if (local == null) return;
    try {
      if (isOutgoing) {
        await _history.saveCallForBoth(
          callId: callId,
          callerUid: local,
          callerName: _localName ?? 'Me',
          callerPhoto: _localPhoto,
          calleeUid: peerUid,
          calleeName: peerName,
          calleePhoto: peerPhoto,
          isVideo: isVideo,
          callerStatus: callerStatus,
          calleeStatus: calleeStatus,
          startedAt: startedAt,
          durationSec: durationSec,
        );
      } else {
        await _history.saveCallForBoth(
          callId: callId,
          callerUid: peerUid,
          callerName: peerName,
          callerPhoto: peerPhoto,
          calleeUid: local,
          calleeName: _localName ?? 'Me',
          calleePhoto: _localPhoto,
          isVideo: isVideo,
          callerStatus: callerStatus,
          calleeStatus: calleeStatus,
          startedAt: startedAt,
          durationSec: durationSec,
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
