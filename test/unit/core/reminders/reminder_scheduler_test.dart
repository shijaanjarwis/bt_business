import 'package:bt_business/core/accounting/transaction_types.dart';
import 'package:bt_business/core/logging/logger.dart';
import 'package:bt_business/core/reminders/reminder_models.dart';
import 'package:bt_business/core/reminders/reminder_notification_port.dart';
import 'package:bt_business/core/reminders/reminder_schedule_tracker.dart';
import 'package:bt_business/core/reminders/reminder_scheduler.dart';
import 'package:bt_business/core/reminders/reminder_snooze_store.dart';
import 'package:bt_business/data/local/database/tables/accounting_tables.dart';
import 'package:bt_business/data/local/reminders/reminder_local_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/dashboard_test_data.dart';

class _NoopLogger implements Logger {
  @override
  void debug(String message) {}

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void info(String message) {}

  @override
  void warning(String message) {}
}

class _TrackingNotifications implements ReminderNotificationPort {
  final cancelled = <String>[];
  final scheduled = <String>[];
  var groupedScheduled = 0;

  @override
  Future<void> cancelGroupedReminders() async {}

  @override
  Future<void> cancelReminderNotifications(String transactionId) async {
    cancelled.add(transactionId);
  }

  @override
  Future<void> scheduleForReminder(
    ReminderEntry entry, {
    DateTime? reference,
  }) async {
    scheduled.add(entry.transactionId);
  }

  @override
  Future<void> scheduleGroupedReminders({
    required List<ReminderEntry> entries,
    DateTime? reference,
  }) async {
    groupedScheduled++;
    scheduled.addAll(entries.map((e) => e.transactionId));
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
  });

  late Database db;
  late ReminderLocalDataSource datasource;
  late _TrackingNotifications notifications;
  late ReminderScheduler scheduler;
  late String businessId;

  setUp(() async {
    db = await createTestDatabase();
    businessId = await seedTestBusiness(db);
    datasource = ReminderLocalDataSource(db);
    notifications = _TrackingNotifications();
    scheduler = ReminderScheduler(
      datasource,
      notifications,
      ReminderScheduleTracker.create(),
      ReminderSnoozeStore.create(),
      _NoopLogger(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('reschedule cancels notifications for completed transactions only', () async {
    const completedId = 'completed-sale';
    const activeId = 'active-sale';
    final partyId = await insertCustomer(
      db: db,
      businessId: businessId,
      name: 'Raaj',
    );

    await db.insert(TransactionsTable.tableName, {
      TransactionsTable.id: activeId,
      TransactionsTable.businessId: businessId,
      TransactionsTable.type: TransactionTypes.sale,
      TransactionsTable.date: '2026-07-04',
      TransactionsTable.partyId: partyId,
      TransactionsTable.totalAmount: 10000,
      TransactionsTable.paidAmount: 0,
      TransactionsTable.dueAmount: 10000,
      TransactionsTable.reminderDate: '2026-07-04',
      TransactionsTable.createdAt: DateTime.now().toIso8601String(),
      TransactionsTable.updatedAt: DateTime.now().toIso8601String(),
    });

    final tracker = ReminderScheduleTracker.create();
    await tracker.saveScheduledTransactionIds({completedId, activeId});

    await scheduler.reschedule(reference: DateTime(2026, 7, 4));

    expect(notifications.cancelled, contains(completedId));
    expect(notifications.scheduled, contains(activeId));
  });

  test('full payment removes reminder from due list and cancels future slots', () async {
    final partyId = await insertCustomer(
      db: db,
      businessId: businessId,
      name: 'Raaj',
    );

    await db.insert(TransactionsTable.tableName, {
      TransactionsTable.id: 'sale-1',
      TransactionsTable.businessId: businessId,
      TransactionsTable.type: TransactionTypes.sale,
      TransactionsTable.date: '2026-07-04',
      TransactionsTable.partyId: partyId,
      TransactionsTable.totalAmount: 15000,
      TransactionsTable.paidAmount: 0,
      TransactionsTable.dueAmount: 15000,
      TransactionsTable.reminderDate: '2026-07-04',
      TransactionsTable.createdAt: DateTime.now().toIso8601String(),
      TransactionsTable.updatedAt: DateTime.now().toIso8601String(),
    });

    await ReminderScheduleTracker.create()
        .saveScheduledTransactionIds({'sale-1'});

    await scheduler.reschedule(reference: DateTime(2026, 7, 4));
    expect(notifications.scheduled, contains('sale-1'));

    await db.update(
      TransactionsTable.tableName,
      {
        TransactionsTable.paidAmount: 15000,
        TransactionsTable.dueAmount: 0,
        TransactionsTable.reminderDate: null,
      },
      where: '${TransactionsTable.id} = ?',
      whereArgs: ['sale-1'],
    );

    notifications.cancelled.clear();
    notifications.scheduled.clear();

    await scheduler.reschedule(reference: DateTime(2026, 7, 4));

    expect(notifications.cancelled, contains('sale-1'));
    expect(notifications.scheduled, isNot(contains('sale-1')));
  });

  test('partial payment keeps reminder scheduled with updated amount', () async {
    final partyId = await insertCustomer(
      db: db,
      businessId: businessId,
      name: 'Raaj',
    );

    await db.insert(TransactionsTable.tableName, {
      TransactionsTable.id: 'sale-partial',
      TransactionsTable.businessId: businessId,
      TransactionsTable.type: TransactionTypes.sale,
      TransactionsTable.date: '2026-07-04',
      TransactionsTable.partyId: partyId,
      TransactionsTable.totalAmount: 20000,
      TransactionsTable.paidAmount: 5000,
      TransactionsTable.dueAmount: 15000,
      TransactionsTable.reminderDate: '2026-07-04',
      TransactionsTable.createdAt: DateTime.now().toIso8601String(),
      TransactionsTable.updatedAt: DateTime.now().toIso8601String(),
    });

    await ReminderScheduleTracker.create()
        .saveScheduledTransactionIds({'sale-partial'});

    await scheduler.reschedule(reference: DateTime(2026, 7, 4));

    expect(notifications.scheduled, contains('sale-partial'));

    final due = await datasource.fetchDueReminders(
      asOf: DateTime(2026, 7, 4),
    );
    expect(due.single.amount, 15000);
    expect(due.single.paidAmount, 5000);
  });

  test('multiple due reminders schedule grouped notification', () async {
    final partyA = await insertCustomer(db: db, businessId: businessId, name: 'Raaj');
    final partyB = await insertCustomer(db: db, businessId: businessId, name: 'Mateen');
    final partyC = await insertCustomer(db: db, businessId: businessId, name: 'Akram');

    for (final row in [
      ('s1', partyA, 15000),
      ('s2', partyB, 22000),
      ('s3', partyC, 9000),
    ]) {
      await db.insert(TransactionsTable.tableName, {
        TransactionsTable.id: row.$1,
        TransactionsTable.businessId: businessId,
        TransactionsTable.type: TransactionTypes.sale,
        TransactionsTable.date: '2026-07-04',
        TransactionsTable.partyId: row.$2,
        TransactionsTable.totalAmount: row.$3,
        TransactionsTable.paidAmount: 0,
        TransactionsTable.dueAmount: row.$3,
        TransactionsTable.reminderDate: '2026-07-04',
        TransactionsTable.createdAt: DateTime.now().toIso8601String(),
        TransactionsTable.updatedAt: DateTime.now().toIso8601String(),
      });
    }

    notifications.scheduled.clear();
    await scheduler.reschedule(reference: DateTime(2026, 7, 4));

    expect(notifications.groupedScheduled, 1);
    expect(notifications.scheduled, containsAll(['s1', 's2', 's3']));
  });

  test('snoozed reminder is excluded from notification schedule', () async {
    final partyId = await insertCustomer(db: db, businessId: businessId, name: 'Raaj');

    await db.insert(TransactionsTable.tableName, {
      TransactionsTable.id: 'snoozed-sale',
      TransactionsTable.businessId: businessId,
      TransactionsTable.type: TransactionTypes.sale,
      TransactionsTable.date: '2026-07-04',
      TransactionsTable.partyId: partyId,
      TransactionsTable.totalAmount: 10000,
      TransactionsTable.paidAmount: 0,
      TransactionsTable.dueAmount: 10000,
      TransactionsTable.reminderDate: '2026-07-04',
      TransactionsTable.createdAt: DateTime.now().toIso8601String(),
      TransactionsTable.updatedAt: DateTime.now().toIso8601String(),
    });

    final snoozeStore = ReminderSnoozeStore.create();
    await snoozeStore.snoozeUntil(
      'snoozed-sale',
      DateTime(2026, 7, 4, 12),
    );

    notifications.scheduled.clear();
    await ReminderScheduler(
      datasource,
      notifications,
      ReminderScheduleTracker.create(),
      snoozeStore,
      _NoopLogger(),
    ).reschedule(reference: DateTime(2026, 7, 4, 9));

    expect(notifications.scheduled, isEmpty);
    expect(notifications.groupedScheduled, 0);
  });
}
