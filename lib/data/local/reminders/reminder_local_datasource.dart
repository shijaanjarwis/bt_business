import 'package:sqflite/sqflite.dart';

import '../../../core/accounting/transaction_types.dart';
import '../../../core/reminders/reminder_models.dart';
import '../../../core/reminders/reminder_service.dart';
import '../../../features/business/data/datasources/business_table.dart';
import '../../local/database/tables/accounting_tables.dart';

/// SQLite queries for reminder dashboard and notifications — offline only.
final class ReminderLocalDataSource {
  const ReminderLocalDataSource(this._db);

  final Database _db;

  Future<String?> _businessId() async {
    final rows = await _db.query(BusinessTable.tableName, limit: 1);
    if (rows.isEmpty) return null;
    return rows.first[BusinessTable.id] as String;
  }

  Future<List<ReminderEntry>> fetchActiveReminders() async {
    final businessId = await _businessId();
    if (businessId == null) return [];

    final rows = await _db.rawQuery(
      '''
      SELECT
        t.${TransactionsTable.id} AS id,
        t.${TransactionsTable.type} AS type,
        t.${TransactionsTable.date} AS date,
        t.${TransactionsTable.partyId} AS party_id,
        t.${TransactionsTable.totalAmount} AS total_amount,
        t.${TransactionsTable.paidAmount} AS paid_amount,
        t.${TransactionsTable.dueAmount} AS due_amount,
        t.${TransactionsTable.reminderDate} AS reminder_date,
        t.${TransactionsTable.notes} AS notes,
        p.${PartiesTable.name} AS party_name,
        p.${PartiesTable.phone} AS party_phone
      FROM ${TransactionsTable.tableName} t
      INNER JOIN ${PartiesTable.tableName} p ON t.${TransactionsTable.partyId} = p.${PartiesTable.id}
      WHERE t.${TransactionsTable.businessId} = ?
        AND t.${TransactionsTable.deletedAt} IS NULL
        AND t.${TransactionsTable.reminderDate} IS NOT NULL
        AND (
          (t.${TransactionsTable.type} IN (?, ?) AND t.${TransactionsTable.dueAmount} > 0)
          OR t.${TransactionsTable.type} IN (?, ?)
        )
      ORDER BY t.${TransactionsTable.reminderDate} ASC, t.${TransactionsTable.createdAt} DESC
      ''',
      [
        businessId,
        TransactionTypes.sale,
        TransactionTypes.purchase,
        TransactionTypes.paymentReceived,
        TransactionTypes.paymentPaid,
      ],
    );

    return rows.map(ReminderService.mapRow).toList();
  }

  /// Today + overdue reminders for dashboard section and morning notifications.
  Future<List<ReminderEntry>> fetchDueReminders({DateTime? asOf}) async {
    final all = await fetchActiveReminders();
    final ref = asOf ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);

    return all.where((entry) {
      final due = DateTime(
        entry.reminderDate.year,
        entry.reminderDate.month,
        entry.reminderDate.day,
      );
      return !due.isAfter(today);
    }).toList();
  }

  Future<ReminderDashboardSummary> fetchSummary({DateTime? asOf}) async {
    final entries = await fetchActiveReminders();
    return ReminderService.summarize(entries, reference: asOf);
  }
}
