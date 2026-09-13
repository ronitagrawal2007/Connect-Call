import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/call_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/users_provider.dart';
import '../history/call_history_screen.dart';

/// Home tab on a solid background (white in light, black in dark):
/// greeting + avatar, search pill, promo card, recent calls.
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final me = context.watch<AuthProvider>().currentUser;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => context.read<UsersProvider>().fetchUsers(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Good morning,',
                            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                        Text('${me?.name.split(' ').first ?? 'there'} 👋',
                            style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: scheme.primaryContainer,
                    backgroundImage: (me?.photoUrl.isNotEmpty ?? false)
                        ? CachedNetworkImageProvider(me!.photoUrl)
                        : null,
                    child: (me?.photoUrl.isEmpty ?? true)
                        ? Text((me?.name.isNotEmpty ?? false) ? me!.name[0].toUpperCase() : '?',
                            style: text.titleMedium)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Search pill
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search people...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (v) => context.read<UsersProvider>().setSearch(v),
              ),
              const SizedBox(height: 16),
              // Promo card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.wifi_calling_3_outlined, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Stay connected',
                              style: TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                          SizedBox(height: 2),
                          Text('Make calls, catch up with friends and family.',
                              style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text('Recent Calls',
                      style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {},
                    child: Text('See all',
                        style: text.bodySmall?.copyWith(color: scheme.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _RecentCalls(meUid: me?.uid ?? ''),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentCalls extends StatelessWidget {
  final String meUid;
  const _RecentCalls({required this.meUid});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    if (meUid.isEmpty) return const SizedBox.shrink();
    return StreamBuilder<List<CallModel>>(
      stream: CallHistoryScreen.historyStreamFor(meUid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }
        if (snap.hasError) {
          return Text('Recent calls unavailable.',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant));
        }
        final items = (snap.data ?? []).take(4).toList();
        if (items.isEmpty) {
          return Text('Calls you make will show up here.',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant));
        }
        return Column(
          children: items.map((c) {
            final bad = c.status == 'missed';
            final accent = bad ? scheme.error : scheme.primary;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: scheme.primaryContainer,
                    backgroundImage:
                        c.peerPhoto.isNotEmpty ? CachedNetworkImageProvider(c.peerPhoto) : null,
                    child: c.peerPhoto.isEmpty
                        ? Text(c.peerName.isNotEmpty ? c.peerName[0].toUpperCase() : '?',
                            style: text.titleMedium)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.peerName,
                            style: text.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(c.isVideo ? Icons.videocam : Icons.call,
                                size: 12, color: accent),
                            const SizedBox(width: 4),
                            Text(
                              '${c.isVideo ? 'Video' : 'Audio'} call · ${_relative(c.startedAt)}',
                              style: text.bodySmall?.copyWith(
                                  color: bad ? scheme.error : scheme.onSurfaceVariant, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(c.isVideo ? Icons.videocam : Icons.call,
                        size: 16, color: accent),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _relative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}';
  }
}
