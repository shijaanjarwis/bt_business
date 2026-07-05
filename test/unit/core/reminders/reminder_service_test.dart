import 'package:bt_business/core/accounting/transaction_types.dart';
import 'package:bt_business/core/reminders/reminder_models.dart';
import 'package:bt_business/core/reminders/reminder_navigation.dart';
import 'package:bt_business/core/reminders/reminder_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReminderService', () {
    test('sale is pending when due amount is positive', () {
      expect(
        ReminderService.isPending(
          transactionType: TransactionTypes.sale,
          dueAmount: 18000,
          reminderDate: DateTime(2026, 7, 3),
        ),
        isTrue,
      );
    });

    test('sale clears reminder when due amount is zero', () {
      final effective = ReminderService.effectiveReminderDate(
        transactionType: TransactionTypes.sale,
        dueAmount: 0,
        requestedReminderDate: DateTime(2026, 7, 3),
      );
      expect(effective, isNull);
    });

    test('payment pending only when reminder date is set', () {
      expect(
        ReminderService.isPending(
          transactionType: TransactionTypes.paymentReceived,
          dueAmount: 0,
          reminderDate: null,
        ),
        isFalse,
      );
      expect(
        ReminderService.isPending(
          transactionType: TransactionTypes.paymentReceived,
          dueAmount: 0,
          reminderDate: DateTime(2026, 7, 1),
        ),
        isTrue,
      );
    });

    test('reminder amount uses remaining for credit sale', () {
      expect(
        ReminderService.reminderAmount(
          transactionType: TransactionTypes.sale,
          totalAmount: 30000,
          dueAmount: 18000,
        ),
        18000,
      );
    });

    test('due labels for today tomorrow and overdue', () {
      final today = DateTime(2026, 6, 30);
      expect(
        ReminderService.dueLabel(DateTime(2026, 6, 30), reference: today),
        'Today',
      );
      expect(
        ReminderService.dueLabel(DateTime(2026, 7, 1), reference: today),
        'Tomorrow',
      );
      expect(
        ReminderService.dueLabel(DateTime(2026, 6, 28), reference: today),
        'Overdue by 2 days',
      );
    });

    test('summarize buckets receivable and payable totals', () {
      final summary = ReminderService.summarize(
        [
          ReminderEntry(
            transactionId: 's1',
            transactionType: TransactionTypes.sale,
            partyId: 'p1',
            partyName: 'Mateen Traders',
            amount: 18000,
            reminderDate: DateTime(2026, 6, 30),
            dueAmount: 18000,
            direction: ReminderDirection.receive,
          ),
          ReminderEntry(
            transactionId: 'p1',
            transactionType: TransactionTypes.purchase,
            partyId: 'p2',
            partyName: 'Kashif Iron Store',
            amount: 12500,
            reminderDate: DateTime(2026, 6, 28),
            dueAmount: 12500,
            direction: ReminderDirection.payment,
          ),
        ],
        reference: DateTime(2026, 6, 30),
      );

      expect(summary.receiveToday, 18000);
      expect(summary.payToday, 0);
      expect(summary.overduePay, 12500);
      expect(summary.pendingReceivable, 18000);
      expect(summary.pendingPayable, 12500);
    });

    test('morning notification combines party lines without spamming', () {
      final entries = [
        ReminderEntry(
          transactionId: 's1',
          transactionType: TransactionTypes.sale,
          partyId: 'p1',
          partyName: 'Mateen Traders',
          amount: 27896,
          reminderDate: DateTime(2026, 6, 30),
          dueAmount: 27896,
          direction: ReminderDirection.receive,
        ),
        ReminderEntry(
          transactionId: 'p1',
          transactionType: TransactionTypes.purchase,
          partyId: 'p2',
          partyName: 'Bharat Steel',
          amount: 14500,
          reminderDate: DateTime(2026, 6, 30),
          dueAmount: 14500,
          direction: ReminderDirection.payment,
        ),
      ];

      final body = ReminderService.buildMorningNotificationBody(
        dueTodayAndOverdue: entries,
        summary: ReminderService.summarize(entries, reference: DateTime(2026, 6, 30)),
        reference: DateTime(2026, 6, 30),
      );

      expect(body, contains('Mateen Traders'));
      expect(body, contains('Bharat Steel'));
      expect(body, contains('Today receive'));
      expect(body, contains('Today payment'));
    });

    test('morning notification adds count when many reminders exist', () {
      final entries = List.generate(
        4,
        (index) => ReminderEntry(
          transactionId: 's$index',
          transactionType: TransactionTypes.sale,
          partyId: 'p$index',
          partyName: 'Party $index',
          amount: 1000,
          reminderDate: DateTime(2026, 6, 30),
          dueAmount: 1000,
          direction: ReminderDirection.receive,
        ),
      );

      final body = ReminderService.buildMorningNotificationBody(
        dueTodayAndOverdue: entries,
        summary: ReminderService.summarize(entries, reference: DateTime(2026, 6, 30)),
        reference: DateTime(2026, 6, 30),
      );

      expect(body, contains('4 pending reminders today'));
    });

    test('groupByParty merges entries by party ID not name', () {
      final groups = ReminderService.groupByParty([
        ReminderEntry(
          transactionId: 's1',
          transactionType: TransactionTypes.sale,
          partyId: 'p1',
          partyName: 'Mateen',
          partyPhone: '9876543210',
          amount: 399269,
          reminderDate: DateTime(2026, 5, 1),
          dueAmount: 399269,
          direction: ReminderDirection.receive,
        ),
        ReminderEntry(
          transactionId: 's2',
          transactionType: TransactionTypes.sale,
          partyId: 'p1',
          partyName: 'Mateen',
          partyPhone: '9876543210',
          amount: 30000,
          reminderDate: DateTime(2026, 6, 1),
          dueAmount: 30000,
          direction: ReminderDirection.receive,
        ),
        ReminderEntry(
          transactionId: 's3',
          transactionType: TransactionTypes.sale,
          partyId: 'p1',
          partyName: 'Mateen',
          partyPhone: '9876543210',
          amount: 12500,
          reminderDate: DateTime(2026, 7, 1),
          dueAmount: 12500,
          direction: ReminderDirection.receive,
        ),
        ReminderEntry(
          transactionId: 's4',
          transactionType: TransactionTypes.sale,
          partyId: 'p2',
          partyName: 'Mateen',
          partyPhone: '9999999999',
          amount: 5000,
          reminderDate: DateTime(2026, 4, 1),
          dueAmount: 5000,
          direction: ReminderDirection.receive,
        ),
      ]);

      expect(groups.length, 2);
      expect(groups.firstWhere((g) => g.partyId == 'p1').entryCount, 3);
      expect(
        groups.firstWhere((g) => g.partyId == 'p1').totalPendingAmount,
        441769,
      );
      expect(
        groups.firstWhere((g) => g.partyId == 'p1').oldestDueDate,
        DateTime(2026, 5, 1),
      );
      expect(groups.firstWhere((g) => g.partyId == 'p2').entryCount, 1);
    });

    test('notification payload opens correct detail route', () {
      expect(
        reminderDetailPathFromPayload('${TransactionTypes.sale}:abc'),
        '/sales/abc',
      );
      expect(
        reminderDetailPathFromPayload('${TransactionTypes.paymentPaid}:xyz'),
        '/payments/xyz',
      );
    });
  });
}
