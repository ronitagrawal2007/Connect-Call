import 'package:flutter_test/flutter_test.dart';

import 'package:connectcall/core/utils/time_utils.dart';

void main() {
  group('TimeUtils.formatDuration', () {
    test('formats seconds as MM:SS', () {
      expect(TimeUtils.formatDuration(0), '00:00');
      expect(TimeUtils.formatDuration(5), '00:05');
      expect(TimeUtils.formatDuration(65), '01:05');
      expect(TimeUtils.formatDuration(3599), '59:59');
    });

    test('formats hours as HH:MM:SS', () {
      expect(TimeUtils.formatDuration(3600), '01:00:00');
      expect(TimeUtils.formatDuration(3665), '01:01:05');
    });
  });
}
