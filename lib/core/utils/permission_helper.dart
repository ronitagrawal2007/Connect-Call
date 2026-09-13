import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Request microphone (+ camera for video) before a call.
/// Returns true if all required permissions granted.
/// Handles denied / permanentlyDenied by showing a dialog with Open Settings.
class PermissionHelper {
  static Future<bool> ensureCallPermissions(
    BuildContext context, {
    required bool isVideo,
  }) async {
    final List<Permission> needed = [
      Permission.microphone,
      if (isVideo) Permission.camera,
    ];

    Map<Permission, PermissionStatus> statuses = await needed.request();

    final bool allGranted =
        statuses.values.every((s) => s.isGranted || s.isLimited);
    if (allGranted) return true;

    // Check permanently denied
    bool permanentlyDenied = statuses.entries
        .any((e) => e.value.isPermanentlyDenied);

    if (!context.mounted) return false;

    if (permanentlyDenied) {
      final open = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Permission required'),
          content: Text(
            isVideo
                ? 'Microphone and Camera are needed for video calls. Please enable them in Settings.'
                : 'Microphone is needed for audio calls. Please enable it in Settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      if (open == true) {
        await openAppSettings();
      }
      return false;
    }

    // Temporarily denied
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Call permission denied. Please allow to continue.'),
        ),
      );
    }
    return false;
  }
}
