import 'package:bt_business/core/accounting/transaction_types.dart';
import 'package:bt_business/core/reminders/reminder_models.dart';
import 'package:bt_business/core/reminders/reminder_notification_ids.dart';
import 'package:bt_business/core/reminders/reminder_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReminderNotificationIds', () {
    test('assigns distinct morning afternoon evening IDs per transaction', () {
      const txId = 'sale-abc-123';
      final ids = ReminderNotificationIds.forTransaction(txId);

      expect(ids.morning, isNot(ids.afternoon));
      expect(ids.afternoon, isNot(ids.evening));
      expect(ids.morning, isNot(ids.evening));
    });

    test('different transactions get different ID buckets', () {
      final a = ReminderNotificationIds.forTransaction('tx-a');
      final b = ReminderNotificationIds.forTransaction('tx-b');

      expect(a.morning, isNot(b.morning));
    });

    test('IDs are stable for the same transaction', () {
      const txId = 'stable-tx-id';
      final first = ReminderNotificationIds.forTransaction(txId);
      final second = ReminderNotificationIds.forTransaction(txId);

      expect(first.morning, second.morning);
      expect(first.afternoon, second.afternoon);
      expect(first.evening, second.evening);
    });
  });

  group('Partial payment notification copy', () {
    test('afternoon notification shows remaining balance not original total', () {
      final content = ReminderService.buildNotificationContent(
        level: ReminderNotificationLevel.afternoon,
        dueTodayAndOverdue: [
          ReminderEntry(
            transactionId: 's1',
            transactionType: TransactionTypes.sale,
            partyId: 'p1',
            partyName: 'Raaj',
            amount: 15000,
            reminderDate: DateTime(2026, 7, 4),
            dueAmount: 15000,
            direction: ReminderDirection.receive,
          ),
        ],
        reference: DateTime(2026, 7, 4),
      );

      expect(content.body, contains('₹15,000'));
      expect(content.body, contains('abhi bhi baaki hai'));
      expect(content.body, isNot(contains('₹20,000')));
    });

    test('single reminder payload targets transaction detail', () {
      final entry = ReminderEntry(
        transactionId: 's1',
        transactionType: TransactionTypes.sale,
        partyId: 'p1',
        partyName: 'Raaj',
        amount: 15000,
        reminderDate: DateTime(2026, 7, 4),
        dueAmount: 15000,
        direction: ReminderDirection.receive,
      );

      expect(
        ReminderService.notificationPayload(entry),
        '${TransactionTypes.sale}:s1',
      );
    });
  });
}
