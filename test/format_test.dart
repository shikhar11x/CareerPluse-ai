import 'package:careerpulse_ai/core/utils/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatClock', () {
    test('formats minutes and seconds', () {
      expect(formatClock(const Duration(seconds: 83)), '01:23');
      expect(formatClock(const Duration(seconds: 5)), '00:05');
      expect(formatClock(const Duration(minutes: 60)), '60:00');
    });

    test('never shows a negative time', () {
      expect(formatClock(const Duration(seconds: -30)), '00:00');
      expect(formatClock(Duration.zero), '00:00');
    });
  });

  group('formatShortDate', () {
    test('shows day and short month', () {
      expect(formatShortDate(DateTime(2026, 10, 30)), '30 Oct');
      expect(formatShortDate(DateTime(2026, 1, 2)), '2 Jan');
    });
  });
}