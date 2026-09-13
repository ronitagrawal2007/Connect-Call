import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/time_utils.dart';
import '../models/call_model.dart';

/// One call-history row. Facts are separated by layout and weight —
/// avatar | name + direction / time | type icon + status — never a
/// single joined string.
class CallHistoryRow extends StatelessWidget {
  final CallModel call;

  const CallHistoryRow({super.key, required this.call});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final bool bad = call.status == 'missed' ||
        call.status == 'rejected' ||
        call.status == 'failed';
    final Color accent = bad ? AppTheme.danger : scheme.primary;

    final String status;
    switch (call.status) {
      case 'missed':
        status = 'Missed';
      case 'rejected':
        status = 'Rejected';
      case 'failed':
        status = 'Failed';
      default:
        status = call.durationSec > 0
            ? TimeUtils.formatDuration(call.durationSec)
            : 'Completed';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: scheme.primaryContainer,
            child: Text(
              call.peerName.isNotEmpty
                  ? call.peerName[0].toUpperCase()
                  : '?',
              style: text.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        call.peerName,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: bad ? AppTheme.danger : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      call.direction == 'incoming'
                          ? Icons.call_received
                          : Icons.call_made,
                      size: 16,
                      color: bad
                          ? AppTheme.danger
                          : scheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  TimeUtils.formatHistoryTime(call.startedAt),
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(
                call.isVideo ? Icons.videocam : Icons.call,
                size: 22,
                color: accent,
              ),
              const SizedBox(height: 4),
              Text(
                status,
                style: text.bodySmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
