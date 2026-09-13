import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import '../core/constants/app_constants.dart';
import '../models/call_model.dart';

typedef IncomingCallCallback = void Function(CallSession session);
typedef CallEventCallback = void Function(
    String callID, ZegoCallUser user, String extra);

/// Thrown when OUR device is not connected to the Zego signaling service.
/// Fix: check internet / wait for reconnect — NOT a peer problem.
class SignalingOfflineException implements Exception {
  final String message;
  const SignalingOfflineException(
      [this.message =
          'Not connected to the call service. Check your internet and try again.']);
  @override
  String toString() => message;
}

/// Thrown when the invitation could not be delivered to the peer
/// (peer ZIM-offline, busy, or blocked). Fix: peer must have the app
/// open in the foreground — the green dot is Firestore presence,
/// not Zego reachability.
class PeerUnreachableException implements Exception {
  final String peerName;
  const PeerUnreachableException(this.peerName);
  @override
  String toString() =>
      'Could not reach $peerName. Ask them to open the app and try again.';
}

/// Singleton wrapper around Zego invitation service.
/// - initZego(uid, userName) on login
/// - sendCallInvitation() for outgoing calls (Zego ZIM signaling)
/// - accept / reject / cancel delegate to Zego SDK
/// - invitationEvents forwarded to CallProvider via callbacks
/// History persistence is done by CallProvider via HistoryService
/// (saved for BOTH users) — this satisfies "sendCallInvitation() + Firestore doc".
class CallingService {
  CallingService._();
  static final CallingService instance = CallingService._();

  bool _initialized = false;
  String? _userId;
  String _userName = '';
  StreamSubscription? _connectionSub;
  ZegoSignalingPluginConnectionState _signalState =
      ZegoSignalingPluginConnectionState.disconnected;

  IncomingCallCallback? onIncomingReceived;
  void Function(String callID)? onIncomingCanceled;
  void Function(String callID)? onIncomingTimeout;
  void Function(String callID, ZegoCallUser callee)? onOutgoingAccepted;
  void Function(String callID, ZegoCallUser callee, String customData)?
      onOutgoingDeclined;
  void Function(String callID, ZegoCallUser callee, String customData)?
      onOutgoingBusy;
  void Function(String callID, List<ZegoCallUser> callees, bool isVideo)?
      onOutgoingTimeout;

  bool get isInitialized => _initialized;

  /// Live ZIM signaling state. `send()` only succeeds while connected.
  bool get isSignalingConnected =>
      _signalState == ZegoSignalingPluginConnectionState.connected;

  Future<void> initZego({
    required String uid,
    required String userName,
    GlobalKey<NavigatorState>? navigatorKey,
  }) async {
    final zegoUserId = uid.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    final safeName =
        userName.trim().isEmpty ? 'User_${zegoUserId.substring(0, 5)}' : userName.trim();

    // Re-init when user changes.
    if (_initialized && _userId == zegoUserId) return;
    if (_initialized) {
      try {
        await ZegoUIKitPrebuiltCallInvitationService().uninit();
      } catch (_) {}
      _initialized = false;
    }

    await ZegoUIKitPrebuiltCallInvitationService().init(
      appID: ZEGO_APP_ID,
      appSign: ZEGO_APP_SIGN,
      userID: zegoUserId,
      userName: safeName,
      plugins: [ZegoUIKitSignalingPlugin()],
      requireConfig: (ZegoCallInvitationData data) {
        final bool isVideo =
            data.type == ZegoCallInvitationType.videoCall;
        if (isVideo) {
          return ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall();
        }
        return ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();
      },
      invitationEvents: ZegoUIKitPrebuiltCallInvitationEvents(
        onIncomingCallReceived:
            (callID, caller, callType, callees, customData) {
          final session = CallSession(
            callId: callID,
            peerId: caller.id,
            peerName: caller.name.isEmpty ? 'Unknown' : caller.name,
            peerPhoto: _peerPhotoFromCustomData(customData),
            isVideo: callType == ZegoCallInvitationType.videoCall,
            isOutgoing: false,
            createdAt: DateTime.now(),
          );
          onIncomingReceived?.call(session);
        },
        onIncomingCallCanceled: (callID, caller, customData) {
          onIncomingCanceled?.call(callID);
        },
        onIncomingCallTimeout: (callID, caller) {
          onIncomingTimeout?.call(callID);
        },
        onOutgoingCallAccepted: (callID, callee) {
          onOutgoingAccepted?.call(callID, callee);
        },
        onOutgoingCallDeclined: (callID, callee, customData) {
          onOutgoingDeclined?.call(callID, callee, customData);
        },
        onOutgoingCallRejectedCauseBusy: (callID, callee, customData) {
          onOutgoingBusy?.call(callID, callee, customData);
        },
        onOutgoingCallTimeout: (callID, callees, isVideoCall) {
          onOutgoingTimeout?.call(callID, callees, isVideoCall);
        },
      ),
    );

    _initialized = true;
    _userId = zegoUserId;
    _userName = safeName;
    _watchSignalingConnection();
  }

  void _watchSignalingConnection() {
    _connectionSub?.cancel();
    try {
      _signalState = ZegoUIKit()
          .getSignalingPlugin()
          .getConnectionState();
    } catch (_) {}
    try {
      _connectionSub = ZegoUIKit()
          .getSignalingPlugin()
          .getConnectionStateStream()
          .listen((event) {
        _signalState = event.state;
      });
    } catch (_) {}
  }

  /// Waits (up to [timeout]) for ZIM signaling to become connected.
  /// ZIM login completes asynchronously after init, so call this
  /// before every outgoing invitation instead of assuming readiness.
  Future<bool> ensureSignalingConnected({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (!_initialized) return false;
    if (isSignalingConnected) return true;
    try {
      await ZegoUIKit()
          .getSignalingPlugin()
          .getConnectionStateStream()
          .firstWhere(
            (e) =>
                e.state ==
                ZegoSignalingPluginConnectionState.connected,
          )
          .timeout(timeout);
      return true;
    } catch (_) {
      return isSignalingConnected;
    }
  }

  /// Re-login to ZIM signaling with the last known identity.
  /// Returns true when signaling is connected afterwards.
  Future<bool> reconnectSignaling() async {
    if (_userId == null || _userId!.isEmpty) return false;
    try {
      await ZegoUIKit().getSignalingPlugin().login(
            id: _userId!,
            name: _userName,
          );
    } catch (_) {}
    return ensureSignalingConnected();
  }

  String _peerPhotoFromCustomData(String customData) {
    // We encode peer photo as plain customData string when sending.
    // If customData is JSON-ish, try to extract; else treat as photo url if http.
    if (customData.startsWith('http')) return customData;
    return '';
  }

  /// Send 1-to-1 invitation. Returns callID used (generated if not supplied).
  /// Throws [SignalingOfflineException] when OUR signaling is down and
  /// [PeerUnreachableException] when the invite can't be delivered.
  /// Callers must ensure signaling via [ensureSignalingConnected] first —
  /// this method double-checks and throws instead of failing silently.
  Future<String> sendCallInvitation({
    required String callerId,
    required String callerName,
    String callerPhoto = '',
    required String calleeId,
    required String calleeName,
    required bool isVideo,
    String? callID,
  }) async {
    if (!_initialized) {
      throw const SignalingOfflineException(
          'Call service not initialized. Please login again.');
    }
    if (!isSignalingConnected) {
      final ok = await ensureSignalingConnected();
      if (!ok) throw const SignalingOfflineException();
    }
    final id = callID ??
        'call_${DateTime.now().millisecondsSinceEpoch}_${callerId.length >= 6 ? callerId.substring(0, 6) : callerId}';
    final invitee = ZegoCallUser(calleeId, calleeName);
    final bool ok =
        await ZegoUIKitPrebuiltCallInvitationService().send(
      invitees: [invitee],
      isVideoCall: isVideo,
      callID: id,
      customData: callerPhoto, // carry caller photo to callee
      timeoutSeconds: AppConstants.callTimeoutSeconds,
    );
    if (!ok) {
      throw PeerUnreachableException(calleeName);
    }
    return id;
  }

  Future<bool> acceptInvitation({String customData = ''}) async {
    try {
      return await ZegoUIKitPrebuiltCallInvitationService()
          .accept(customData: customData);
    } catch (_) {
      return false;
    }
  }

  Future<bool> rejectInvitation({String customData = ''}) async {
    try {
      return await ZegoUIKitPrebuiltCallInvitationService()
          .reject(customData: customData);
    } catch (_) {
      return false;
    }
  }

  Future<bool> cancelInvitation({
    required List<ZegoCallUser> callees,
    String customData = '',
  }) async {
    try {
      return await ZegoUIKitPrebuiltCallInvitationService()
          .cancel(callees: callees, customData: customData);
    } catch (_) {
      return false;
    }
  }

  Future<void> uninit() async {
    try {
      await _connectionSub?.cancel();
    } catch (_) {}
    _connectionSub = null;
    _signalState = ZegoSignalingPluginConnectionState.disconnected;
    try {
      await ZegoUIKitPrebuiltCallInvitationService().uninit();
    } catch (_) {}
    _initialized = false;
    _userId = null;
    _userName = '';
  }

  void clearCallbacks() {
    onIncomingReceived = null;
    onIncomingCanceled = null;
    onIncomingTimeout = null;
    onOutgoingAccepted = null;
    onOutgoingDeclined = null;
    onOutgoingBusy = null;
    onOutgoingTimeout = null;
  }
}
