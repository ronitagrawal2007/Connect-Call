import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/time_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/call_provider.dart';
import '../../widgets/call_button.dart';
import 'zego_call.dart';

/// Audio call on theme background (white/black): avatar, name, timer-or-status,
/// and Mute / Speaker / End. System back hangs up, like End does.
class AudioCallScreen extends StatefulWidget {
  const AudioCallScreen({super.key});

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
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
        appBar: AppBar(title: const Text('Audio call')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.call_end_outlined,
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
              config: audioConfig(),
              events: buildCallEvents(context, onEnd: _onRemoteEnd),
            ),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  CircleAvatar(
                    radius: 64,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    backgroundImage: session.peerPhoto.isNotEmpty
                        ? CachedNetworkImageProvider(session.peerPhoto)
                        : null,
                    child: session.peerPhoto.isEmpty
                        ? Text(
                            session.peerName.isNotEmpty
                                ? session.peerName[0].toUpperCase()
                                : '?',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 52,
                                ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    session.peerName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    status,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
                          icon: Icons.volume_up,
                          label: 'Speaker',
                          isActive: call.isSpeakerOn,
                          onPressed: () => context.read<CallProvider>().toggleSpeaker(),
                        ),
                        CallButton(
                          icon: Icons.call_end,
                          label: 'End',
                          isDanger: true,
                          onPressed: _endAndPop,
                        ),
                      ],
                    ),
                  ),
                ],
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
