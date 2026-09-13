import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/time_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/call_provider.dart';
import '../../widgets/call_button.dart';
import 'zego_call.dart';

/// Video call: remote video fullscreen with local PiP (Zego layout),
/// name on a scrim (never bare text), and
/// Mute / Camera / Switch / End. System back hangs up, like End does.
class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({super.key});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _allowPop = false;

  Future<void> _endAndPop() async {
    try {
      await context.read<CallProvider>().end();
    } catch (_) {}
    _allowPop = true;
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _onRemoteEnd() {
    _allowPop = true;
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final call = context.watch<CallProvider>();
    final session = call.currentCall;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Video call')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.videocam_off_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  'No active call',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Start one from Contacts.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final local = context.read<AuthProvider>().currentUser;
    if (local == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    final bool live = call.callStatus == 'connected' || call.callStatus == 'inCall';
    final String status =
        live ? TimeUtils.formatDuration(call.duration) : _statusText(call.callStatus);

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _endAndPop();
      },
      child: Scaffold(
        body: Stack(
          children: [
            ZegoUIKitPrebuiltCall(
              appID: ZEGO_APP_ID,
              appSign: ZEGO_APP_SIGN,
              userID: local.zegoUserId,
              userName: local.name,
              callID: session.callId,
              config: videoConfig(),
              events: buildCallEvents(context, onEnd: _onRemoteEnd),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 24,
                  right: 24,
                  bottom: 24,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      session.peerName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      status,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 24,
                  bottom: MediaQuery.of(context).padding.bottom + 24,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CallButton(
                      icon: call.isMuted ? Icons.mic_off : Icons.mic,
                      label: 'Mute',
                      isActive: call.isMuted,
                      onPressed: () => context.read<CallProvider>().toggleMute(),
                    ),
                    CallButton(
                      icon: call.isCameraOff ? Icons.videocam_off : Icons.videocam,
                      label: 'Camera',
                      isActive: !call.isCameraOff,
                      onPressed: () => context.read<CallProvider>().toggleCamera(),
                    ),
                    CallButton(
                      icon: Icons.cameraswitch,
                      label: 'Switch',
                      onPressed: () => context.read<CallProvider>().switchCamera(),
                    ),
                    const SizedBox(width: 24),
                    CallButton(
                      icon: Icons.call_end,
                      label: 'End',
                      isDanger: true,
                      onPressed: _endAndPop,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusText(String status) {
    switch (status) {
      case 'calling':
        return 'Calling…';
      case 'ringing':
        return 'Ringing…';
      case 'ended':
        return 'Ended';
      default:
        return status;
    }
  }
}
