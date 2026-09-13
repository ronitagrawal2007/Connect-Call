import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import '../../providers/call_provider.dart';

/// Shared Zego wiring for the audio/video screens.
///
/// The prebuilt top/bottom toolbars are hidden — our [CallButton] rows
/// are the only controls. They drive the same engine through
/// CallProvider (which mirrors into the ZegoUIKit singleton), so the
/// room state and our UI can never diverge.
///
/// [onEnd] must make the hosting route poppable and pop it (used when
/// the remote side hangs up).
ZegoUIKitPrebuiltCallEvents buildCallEvents(
  BuildContext context, {
  required VoidCallback onEnd,
}) {
  return ZegoUIKitPrebuiltCallEvents(
    onCallEnd: (event, defaultAction) async {
      try {
        await context.read<CallProvider>().end();
      } catch (_) {}
      onEnd();
    },
    user: ZegoCallUserEvents(
      onEnter: (user) {
        try {
          context.read<CallProvider>().markConnected();
        } catch (_) {}
      },
    ),
  );
}

ZegoUIKitPrebuiltCallConfig audioConfig() {
  final c = ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();
  c.turnOnCameraWhenJoining = false;
  c.turnOnMicrophoneWhenJoining = true;
  c.useSpeakerWhenJoining = true;
  c.topMenuBar.isVisible = false;
  c.bottomMenuBar.isVisible = false;
  return c;
}

ZegoUIKitPrebuiltCallConfig videoConfig() {
  final c = ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall();
  c.turnOnCameraWhenJoining = true;
  c.turnOnMicrophoneWhenJoining = true;
  c.useSpeakerWhenJoining = true;
  c.topMenuBar.isVisible = false;
  c.bottomMenuBar.isVisible = false;
  return c;
}
