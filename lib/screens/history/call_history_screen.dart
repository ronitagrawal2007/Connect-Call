import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/call_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/history_service.dart';
import '../../widgets/common_button.dart';

/// Solid background (white in light, black in dark), left title.
class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({super.key});

  static Stream<List<CallModel>> historyStreamFor(String uid) {
    if (uid.isEmpty) return const Stream.empty();
    return HistoryService().historyStream(uid);
  }

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  String _uid = '';
  Stream<List<CallModel>>? _stream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uid = context.read<AuthProvider>().currentUser?.uid ?? '';
    if (uid != _uid) {
      _uid = uid;
      _stream = CallHistoryScreen.historyStreamFor(_uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    if (_uid.isEmpty) {
      return Scaffold(
        body: Center(child: Text('Not logged in.', style: text.bodyMedium)),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Text('Call History',
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: StreamBuilder<List<CallModel>>(
                stream: _stream,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cloud_off_outlined, size: 40, color: scheme.onSurfaceVariant),
                            const SizedBox(height: 8),
                            Text('Could not load calls.', style: text.titleSmall),
                            const SizedBox(height: 4),
                            Text('Check your connection and try again.',
                                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                            const SizedBox(height: 16),
                            CommonButton(
                                text: 'Retry',
                                isOutlined: true,
                                onPressed: () => setState(() => _stream = CallHistoryScreen.historyStreamFor(_uid))),
                          ],
                        ),
                      ),
                    );
                  }
                  final items = snap.data ?? [];
                  if (items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.call_outlined, size: 40, color: scheme.onSurfaceVariant),
                            const SizedBox(height: 8),
                            Text('No calls yet.', style: text.titleSmall),
                            const SizedBox(height: 4),
                            Text('Calls you make will show up here.',
                                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                    itemBuilder: (context, i) {
                      final c = items[i];
                      final bad = c.status == 'missed';
                      final duration = bad
                          ? 'Missed'
                          : (c.durationSec > 0
                              ? '${(c.durationSec ~/ 60).toString().padLeft(2, '0')}:${(c.durationSec % 60).toString().padLeft(2, '0')}'
                              : '—');
                      final subtitle =
                          '${c.isVideo ? 'Video' : 'Audio'} call · ${_relativeLabel(c.startedAt)}';
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: scheme.primaryContainer,
                          backgroundImage:
                              c.peerPhoto.isNotEmpty ? CachedNetworkImageProvider(c.peerPhoto) : null,
                          child: c.peerPhoto.isEmpty
                              ? Text(c.peerName.isNotEmpty ? c.peerName[0].toUpperCase() : '?',
                                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold))
                              : null,
                        ),
                        title: Text(c.peerName,
                            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        subtitle: Row(
                          children: [
                            Icon(c.isVideo ? Icons.videocam : Icons.call,
                                size: 12, color: scheme.primary),
                            const SizedBox(width: 4),
                            Expanded(
                                child: Text(subtitle,
                                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                                    overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(duration,
                                style: text.bodySmall?.copyWith(
                                    color: bad ? scheme.error : scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Icon(Icons.chevron_right, size: 18, color: scheme.onSurfaceVariant),
                          ],
                        ),
                        onTap: () {},
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relativeLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'Today, ${_fmt(dt)}';
    if (diff.inHours < 24 && dt.day == now.day) return 'Today, ${_fmt(dt)}';
    if (diff.inDays == 1 || (diff.inHours < 48 && dt.day != now.day)) return 'Yesterday, ${_fmt(dt)}';
    return 'Sep ${dt.day}, ${_fmt(dt)}';
  }

  String _fmt(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ap';
  }
}
