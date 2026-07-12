import 'package:bt_business/core/backup/backup_auto_conditions.dart';
import 'package:bt_business/core/backup/backup_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeNextAutomaticBackup', () {
    test('returns tonight 2 AM when before schedule today', () {
      final reference = DateTime(2026, 7, 13, 1, 0);
      final next = computeNextAutomaticBackup(
        reference: reference,
        autoEnabled: true,
        frequency: AutoBackupFrequency.daily,
        lastBackupAt: null,
      );

      expect(next, DateTime(2026, 7, 13, 2));
    });

    test('returns tomorrow 2 AM when already past schedule today', () {
      final reference = DateTime(2026, 7, 13, 3, 0);
      final next = computeNextAutomaticBackup(
        reference: reference,
        autoEnabled: true,
        frequency: AutoBackupFrequency.daily,
        lastBackupAt: DateTime(2026, 7, 13, 2, 30),
      );

      expect(next, DateTime(2026, 7, 14, 2));
    });

    test('returns null when automatic backup disabled', () {
      final next = computeNextAutomaticBackup(
        reference: DateTime(2026, 7, 13, 10),
        autoEnabled: false,
        frequency: AutoBackupFrequency.daily,
        lastBackupAt: null,
      );

      expect(next, isNull);
    });
  });
}
