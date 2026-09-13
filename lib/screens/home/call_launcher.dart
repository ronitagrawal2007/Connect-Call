import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/permission_helper.dart';
import '../../models/user_model.dart';
import '../../providers/call_provider.dart';
import '../../services/calling_service.dart'
    show PeerUnreachableException, SignalingOfflineException;

/// Shared outgoing-call launcher: permission -> provider.startCall -> route.
/// Shows SnackBar/Dialog on error, never crashes.
/// Error mapping:
/// - SignalingOfflineException -> OUR signaling down (internet / reconnect)
/// - PeerUnreachableException  -> PEER needs the app open in foreground
///   (the green dot is Firestore presence, not Zego reachability).
class CallLauncher {
  static void _showCallError(BuildContext context, Object e) {
    final String message;
    if (e is SignalingOfflineException) {
      message = e.message;
    } else if (e is PeerUnreachableException) {
      message = e.toString();
    } else {
      message = 'Could not start call: $e';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
  }
  static Future<void> startAudio(
      BuildContext context, UserModel peer) async {
    if (!peer.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${peer.name} is offline')),
      );
      return;
    }
    final ok = await PermissionHelper.ensureCallPermissions(
      context,
      isVideo: false,
    );
    if (!ok || !context.mounted) return;
    try {
      final callID = await context
          .read<CallProvider>()
          .startCall(peer: peer, isVideo: false);
      if (!context.mounted) return;
      if (callID != null) {
        Navigator.pushNamed(context, AppConstants.routeAudioCall);
      }
    } catch (e) {
      if (!context.mounted) return;
      _showCallError(context, e);
    }
  }

  static Future<void> startVideo(
      BuildContext context, UserModel peer) async {
    if (!peer.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${peer.name} is offline')),
      );
      return;
    }
    final ok = await PermissionHelper.ensureCallPermissions(
      context,
      isVideo: true,
    );
    if (!ok || !context.mounted) return;
    try {
      final callID = await context
          .read<CallProvider>()
          .startCall(peer: peer, isVideo: true);
      if (!context.mounted) return;
      if (callID != null) {
        Navigator.pushNamed(context, AppConstants.routeVideoCall);
      }
    } catch (e) {
      if (!context.mounted) return;
      _showCallError(context, e);
    }
  }
}
