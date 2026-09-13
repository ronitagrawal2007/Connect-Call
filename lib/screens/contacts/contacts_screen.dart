import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/users_provider.dart';
import '../../widgets/user_tile.dart';
import '../home/call_launcher.dart';

/// Solid background (white in light, black in dark), left title, pill search.
class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Text('Contacts',
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
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
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Consumer<UsersProvider>(
                builder: (context, users, _) {
                  if (users.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (users.error != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cloud_off_outlined, size: 48, color: scheme.onSurfaceVariant),
                            const SizedBox(height: 8),
                            Text('Could not load contacts.', style: text.titleMedium),
                            const SizedBox(height: 4),
                            Text('Check your connection and try again.',
                                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    );
                  }
                  final list = users.users;
                  if (list.isEmpty) {
                    final searching = users.searchQuery.trim().isNotEmpty;
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(searching ? Icons.search_off_outlined : Icons.group_add_outlined,
                                size: 48, color: scheme.onSurfaceVariant),
                            const SizedBox(height: 8),
                            Text(searching ? 'No match found.' : 'No contacts yet.',
                                style: text.titleMedium),
                            const SizedBox(height: 4),
                            Text(
                                searching
                                    ? 'Try a different name or email.'
                                    : 'Ask a friend to create an account and they will show up here.',
                                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                                textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                    itemBuilder: (context, i) {
                      final u = list[i];
                      return UserTile(
                        user: u,
                        onAudioCall: () => CallLauncher.startAudio(context, u),
                        onVideoCall: () => CallLauncher.startVideo(context, u),
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
}
