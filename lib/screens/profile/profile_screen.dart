import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import 'edit_profile_screen.dart';

/// Single-colour page (white light / black dark), centered identity,
/// envelope/phone rows, dark-mode toggle, outlined actions.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will appear offline to your contacts.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Stay')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Log out')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await context.read<AuthProvider>().signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppConstants.routeLogin, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final onSurface = scheme.onSurface;
    final onVariant = scheme.onSurfaceVariant;
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.currentUser;
        if (user == null) {
          return Scaffold(
            backgroundColor: scaffoldBg,
            body: Center(child: Text('Not logged in.', style: text.bodyLarge)),
          );
        }
        return Scaffold(
          backgroundColor: scaffoldBg,
          appBar: AppBar(
            backgroundColor: scaffoldBg,
            elevation: 0,
            leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.maybePop(context)),
            actions: const [
              IconButton(
                  icon: Icon(Icons.settings_outlined), onPressed: null),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: scheme.primaryContainer,
                    backgroundImage:
                        user.photoUrl.isNotEmpty ? CachedNetworkImageProvider(user.photoUrl) : null,
                    child: user.photoUrl.isEmpty
                        ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                            style: text.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold, fontSize: 40))
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Text(user.name,
                    textAlign: TextAlign.center,
                    style: text.titleLarge?.copyWith(
                        color: onSurface, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: AppTheme.online, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(user.isOnline ? 'Online' : 'Offline',
                        style: text.bodySmall?.copyWith(color: onVariant)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mail_outline, size: 14, color: onVariant),
                    const SizedBox(width: 6),
                    Text(user.email, style: text.bodySmall?.copyWith(color: onVariant)),
                  ],
                ),
                const SizedBox(height: 24),
                // Dark mode toggle — persisted via ThemeProvider/SharedPreferences.
                Consumer<ThemeProvider>(
                  builder: (context, theme, _) => Card(
                    elevation: 0,
                    color: scheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: scheme.outlineVariant),
                    ),
                    child: SwitchListTile(
                      secondary: Icon(
                        theme.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                        color: onSurface,
                      ),
                      title: Text('Dark Mode',
                          style: text.titleSmall?.copyWith(
                              color: onSurface, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        theme.isDarkMode ? 'Black background' : 'White background',
                        style: text.bodySmall?.copyWith(color: onVariant),
                      ),
                      value: theme.isDarkMode,
                      onChanged: (v) => theme.setDarkMode(v),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit Profile'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.logout, size: 18),
                  label: auth.isLoading
                      ? const SizedBox(
                          height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                    side: const BorderSide(color: AppTheme.danger),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: auth.isLoading ? null : _logout,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
