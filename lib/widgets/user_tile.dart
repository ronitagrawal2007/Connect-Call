import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/user_model.dart';

/// Contact row: avatar, name, presence, audio/video buttons.
/// [onTap] is optional (e.g. opens a contact sheet); the call buttons
/// always remain directly tappable at 48dp.
class UserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onAudioCall;
  final VoidCallback onVideoCall;
  final VoidCallback? onTap;

  const UserTile({
    super.key,
    required this.user,
    required this.onAudioCall,
    required this.onVideoCall,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final presence =
        user.isOnline ? AppTheme.online : AppTheme.offline;
    return ListTile(
      onTap: onTap,
      minTileHeight: 72,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor:
                Theme.of(context).colorScheme.primaryContainer,
            backgroundImage: user.photoUrl.isNotEmpty
                ? CachedNetworkImageProvider(user.photoUrl)
                : null,
            child: user.photoUrl.isEmpty
                ? Text(
                    user.name.isNotEmpty
                        ? user.name[0].toUpperCase()
                        : '?',
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: presence,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
      title: Text(
        user.name,
        style: text.titleMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        user.isOnline ? 'Online' : 'Offline',
        style: text.bodySmall?.copyWith(color: presence),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.call),
            color: Theme.of(context).colorScheme.primary,
            tooltip: 'Audio call',
            onPressed: onAudioCall,
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            color: Theme.of(context).colorScheme.primary,
            tooltip: 'Video call',
            onPressed: onVideoCall,
          ),
        ],
      ),
    );
  }
}
