import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/call_provider.dart';
import '../../widgets/call_button.dart';

/// Incoming call takeover: locked against the back button, one slow
/// pulse ring around the avatar, caller name + call kind,
/// red Decline / green Accept. Solid theme background (white/black).
class IncomingCallScreen extends StatefulWidget {
  const IncomingCallScreen({super.key});

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _dismiss() {
    _allowPop = true;
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Future<void> _decline() async {
    try {
      await context.read<CallProvider>().reject();
    } catch (_) {}
    _dismiss();
  }

  Future<void> _accept(bool isVideo) async {
    try {
      await context.read<CallProvider>().accept();
    } catch (_) {}
    _allowPop = true;
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      isVideo ? AppConstants.routeVideoCall : AppConstants.routeAudioCall,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CallProvider>(
      builder: (context, call, _) {
        final session = call.currentCall;

        if (session == null ||
            session.isOutgoing ||
            call.callStatus == 'idle' ||
            call.callStatus == 'missed' ||
            call.callStatus == 'ended') {
          WidgetsBinding.instance.addPostFrameCallback((_) => _dismiss());
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final text = Theme.of(context).textTheme;
        final scheme = Theme.of(context).colorScheme;
        return PopScope(
          canPop: _allowPop,
          child: Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      session.isVideo ? 'Incoming video call' : 'Incoming audio call',
                      style: text.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 224,
                      height: 224,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _pulse,
                            builder: (_, __) {
                              final t = _pulse.value;
                              return Container(
                                width: 160 + 64 * t,
                                height: 160 + 64 * t,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: scheme.primary
                                        .withValues(alpha: 0.45 * (1 - t)),
                                    width: 2,
                                  ),
                                ),
                              );
                            },
                          ),
                          CircleAvatar(
                            radius: 64,
                            backgroundColor: scheme.primaryContainer,
                            backgroundImage: session.peerPhoto.isNotEmpty
                                ? CachedNetworkImageProvider(session.peerPhoto)
                                : null,
                            child: session.peerPhoto.isEmpty
                                ? Text(
                                    session.peerName.isNotEmpty
                                        ? session.peerName[0].toUpperCase()
                                        : '?',
                                    style: text.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 52,
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      session.peerName,
                      textAlign: TextAlign.center,
                      style: text.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ringing…',
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          CallButton(
                            icon: Icons.call_end,
                            label: 'Decline',
                            isDanger: true,
                            onPressed: _decline,
                          ),
                          CallButton(
                            icon: session.isVideo ? Icons.videocam : Icons.call,
                            label: 'Accept',
                            background: scheme.primary,
                            foreground: scheme.onPrimary,
                            onPressed: () => _accept(session.isVideo),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
