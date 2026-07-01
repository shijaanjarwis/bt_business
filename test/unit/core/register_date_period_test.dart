import 'package:bt_business/core/utils/register_date_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RegisterDateRange', () {
    test('today resolves to single day', () {
      final range = RegisterDateRange.resolve(
        period: RegisterDatePeriod.today,
        now: DateTime(2026, 6, 15, 14, 30),
      );
      expect(range.start, DateTime(2026, 6, 15));
      expect(range.end, DateTime(2026, 6, 15));
    });

    test('thisWeek starts on Monday', () {
      final range = RegisterDateRange.resolve(
        period: RegisterDatePeriod.thisWeek,
        now: DateTime(2026, 6, 18), // Thursday
      );
      expect(range.start, DateTime(2026, 6, 15)); // Monday
      expect(range.end, DateTime(2026, 6, 18));
    });

    test('thisMonth starts on first day of month', () {
      final range = RegisterDateRange.resolve(
        period: RegisterDatePeriod.thisMonth,
        now: DateTime(2026, 6, 18),
      );
      expect(range.start, DateTime(2026, 6, 1));
      expect(range.end, DateTime(2026, 6, 18));
    });

    test('includesDate respects custom range', () {
      final included = RegisterDateRange.includesDate(
        date: DateTime(2026, 6, 10),
        period: RegisterDatePeriod.custom,
        customStart: DateTime(2026, 6, 1),
        customEnd: DateTime(2026, 6, 15),
      );
      final excluded = RegisterDateRange.includesDate(
        date: DateTime(2026, 6, 20),
        period: RegisterDatePeriod.custom,
        customStart: DateTime(2026, 6, 1),
        customEnd: DateTime(2026, 6, 15),
      );
      expect(included, isTrue);
      expect(excluded, isFalse);
    });
  });
}
