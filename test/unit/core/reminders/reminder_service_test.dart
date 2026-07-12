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

    test('resolveStatus marks overdue when date passed', () {
      final entry = ReminderEntry(
        transactionId: 's1',
        transactionType: TransactionTypes.sale,
        partyId: 'p1',
        partyName: 'Raaj',
        amount: 15000,
        reminderDate: DateTime(2026, 6, 28),
        dueAmount: 15000,
        direction: ReminderDirection.receive,
      );

      expect(
        ReminderService.resolveStatus(entry, reference: DateTime(2026, 6, 30)),
        ReminderStatus.overdue,
      );
    });

    test('resolveStatus marks completed when due is zero', () {
      final entry = ReminderEntry(
        transactionId: 's1',
        transactionType: TransactionTypes.sale,
        partyId: 'p1',
        partyName: 'Raaj',
        amount: 0,
        reminderDate: DateTime(2026, 6, 30),
        dueAmount: 0,
        direction: ReminderDirection.receive,
      );

      expect(
        ReminderService.resolveStatus(entry, reference: DateTime(2026, 6, 30)),
        ReminderStatus.completed,
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

    test('morning notification uses Hindi-first single reminder copy', () {
      final content = ReminderService.buildNotificationContent(
        level: ReminderNotificationLevel.morning,
        dueTodayAndOverdue: [
          ReminderEntry(
            transactionId: 's1',
            transactionType: TransactionTypes.sale,
            partyId: 'p1',
            partyName: 'Raaj',
            amount: 15000,
            reminderDate: DateTime(2026, 6, 30),
            dueAmount: 15000,
            direction: ReminderDirection.receive,
          ),
        ],
        reference: DateTime(2026, 6, 30),
      );

      expect(content.title, "Today's Payment Reminder");
      expect(content.body, contains('Raaj se'));
      expect(content.body, contains('₹15,000'));
      expect(content.body, contains('lena hai aaj'));
      expect(content.payload, 'list:receive-today');
    });

    test('afternoon notification says still pending', () {
      final content = ReminderService.buildNotificationContent(
        level: ReminderNotificationLevel.afternoon,
        dueTodayAndOverdue: [
          ReminderEntry(
            transactionId: 's1',
            transactionType: TransactionTypes.sale,
            partyId: 'p1',
            partyName: 'Raaj',
            amount: 15000,
            reminderDate: DateTime(2026, 6, 30),
            dueAmount: 15000,
            direction: ReminderDirection.receive,
          ),
        ],
        reference: DateTime(2026, 6, 30),
      );

      expect(content.title, 'Reminder');
      expect(content.body, contains('abhi bhi baaki hai'));
    });

    test('evening notification is last reminder today', () {
      final content = ReminderService.buildNotificationContent(
        level: ReminderNotificationLevel.evening,
        dueTodayAndOverdue: [
          ReminderEntry(
            transactionId: 's1',
            transactionType: TransactionTypes.sale,
            partyId: 'p1',
            partyName: 'Raaj',
            amount: 15000,
            reminderDate: DateTime(2026, 6, 30),
            dueAmount: 15000,
            direction: ReminderDirection.receive,
          ),
        ],
        reference: DateTime(2026, 6, 30),
      );

      expect(content.title, 'Last Reminder Today');
      expect(content.body, contains('abhi bhi baaki hai'));
    });

    test('grouped morning notification combines parties', () {
      final entries = [
        ReminderEntry(
          transactionId: 's1',
          transactionType: TransactionTypes.sale,
          partyId: 'p1',
          partyName: 'Raaj',
          amount: 15000,
          reminderDate: DateTime(2026, 6, 30),
          dueAmount: 15000,
          direction: ReminderDirection.receive,
        ),
        ReminderEntry(
          transactionId: 's2',
          transactionType: TransactionTypes.sale,
          partyId: 'p2',
          partyName: 'Mateen',
          amount: 25000,
          reminderDate: DateTime(2026, 6, 30),
          dueAmount: 25000,
          direction: ReminderDirection.receive,
        ),
        ReminderEntry(
          transactionId: 's3',
          transactionType: TransactionTypes.sale,
          partyId: 'p3',
          partyName: 'Akram',
          amount: 8000,
          reminderDate: DateTime(2026, 6, 30),
          dueAmount: 8000,
          direction: ReminderDirection.receive,
        ),
      ];

      final content = ReminderService.buildNotificationContent(
        level: ReminderNotificationLevel.morning,
        dueTodayAndOverdue: entries,
        reference: DateTime(2026, 6, 30),
      );

      expect(content.title, "Today's Payment Reminders");
      expect(content.body, contains('3 reminders pending today'));
      expect(content.body, contains('Raaj'));
      expect(content.body, contains('Mateen'));
      expect(content.body, contains('Akram'));
      expect(content.body, contains('Tap to view all reminders'));
      expect(content.payload, 'list:receive-today');
    });

    test('overdue morning notification mentions overdue days', () {
      final content = ReminderService.buildNotificationContent(
        level: ReminderNotificationLevel.morning,
        dueTodayAndOverdue: [
          ReminderEntry(
            transactionId: 's1',
            transactionType: TransactionTypes.sale,
            partyId: 'p1',
            partyName: 'Raaj',
            amount: 15000,
            reminderDate: DateTime(2026, 6, 28),
            dueAmount: 15000,
            direction: ReminderDirection.receive,
          ),
        ],
        reference: DateTime(2026, 6, 30),
      );

      expect(content.body, contains('Overdue by 2 days'));
    });

    test('pay reminder routes to pay-today list', () {
      final payload = ReminderService.notificationListPayload([
        ReminderEntry(
          transactionId: 'p1',
          transactionType: TransactionTypes.purchase,
          partyId: 'p2',
          partyName: 'Sharma Traders',
          amount: 22000,
          reminderDate: DateTime(2026, 6, 30),
          dueAmount: 22000,
          direction: ReminderDirection.payment,
        ),
      ]);

      expect(payload, 'list:pay-today');
      expect(
        reminderNavigationPathFromPayload(payload),
        '/reminders/pay-today',
      );
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

    test('list payload opens receive today screen', () {
      expect(
        reminderNavigationPathFromPayload('list:receive-today'),
        '/reminders/receive-today',
      );
    });
  });
}
