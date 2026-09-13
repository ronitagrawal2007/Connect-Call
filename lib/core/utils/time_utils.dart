import 'package:intl/intl.dart';

class TimeUtils {
  /// Seconds -> MM:SS (or HH:MM:SS when >= 1 hour)
  static String formatDuration(int totalSeconds) {
    final d = Duration(seconds: totalSeconds);
    String two(int n) => n.toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
    }
    return '${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  static String formatHistoryTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thatDay = DateTime(dt.year, dt.month, dt.day);
    final diffDays = today.difference(thatDay).inDays;
    if (diffDays == 0) {
      return DateFormat('hh:mm a').format(dt);
    } else if (diffDays == 1) {
      return 'Yesterday, ${DateFormat('hh:mm a').format(dt)}';
    } else if (diffDays < 7) {
      return DateFormat('EEE, hh:mm a').format(dt);
    }
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }
}
