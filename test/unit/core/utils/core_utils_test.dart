import 'package:bt_business/core/utils/date_formatter.dart';
import 'package:bt_business/core/utils/id_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DateFormatter', () {
    test('formats ISO date', () {
      final formatted = DateFormatter.isoDate(DateTime(2026, 6, 30));
      expect(formatted, '2026-06-30');
    });

    test('parses ISO date strictly', () {
      final parsed = DateFormatter.parseIsoDate('2026-06-30');
      expect(parsed, DateTime(2026, 6, 30));
    });

    test('returns null for invalid ISO date', () {
      expect(DateFormatter.parseIsoDate('30-06-2026'), isNull);
    });
  });

  group('IdGenerator', () {
    test('generates unique UUID v4 values', () {
      final first = IdGenerator.newId();
      final second = IdGenerator.newId();

      expect(first, isNotEmpty);
      expect(second, isNotEmpty);
      expect(first, isNot(equals(second)));
    });
  });
}
