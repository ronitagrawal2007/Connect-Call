import 'package:flutter/material.dart';

/// Round in-call control (mute, speaker, camera, switch, end).
/// [active] marks the on-state; [isActive] is an alias kept for
/// call-site clarity. [isDanger] renders the destructive red style.
class CallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? background;
  final Color? foreground;
  final bool active;
  final bool? isActive;
  final bool isDanger;

  const CallButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.background,
    this.foreground,
    this.active = false,
    this.isActive,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bool on = isActive ?? active;
    final Color bg = isDanger
        ? scheme.error
        : background ??
            (on ? scheme.primary : scheme.surfaceContainerHighest);
    final Color fg = isDanger
        ? scheme.onError
        : foreground ?? (on ? scheme.onPrimary : scheme.onSurface);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(18),
            minimumSize: const Size(64, 64),
            backgroundColor: bg,
            foregroundColor: fg,
          ),
          child: Icon(icon, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
