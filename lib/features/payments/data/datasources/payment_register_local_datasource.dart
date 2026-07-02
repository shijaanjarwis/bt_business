import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../../../../core/accounting/transaction_types.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/reminders/reminder_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../data/local/database/tables/accounting_tables.dart';
import '../../../business/data/datasources/business_table.dart';
import '../../domain/entities/payment_register_entry.dart';
import '../../presentation/models/payment_register_filter.dart';

/// Read-only queries for the jama / payment register UI.
final class PaymentRegisterLocalDataSource {
  const PaymentRegisterLocalDataSource(this._db);

  final Database _db;

  Future<String?> _businessId() async {
    final rows = await _db.query(BusinessTable.tableName, limit: 1);
    if (rows.isEmpty) return null;
    return rows.first[BusinessTable.id] as String;
  }

  Future<List<PaymentRegisterEntry>> fetchPayments({
    PaymentRegisterFilter filter = PaymentRegisterFilter.all,
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
    int offset = 0,
  }) async {
    return _queryPayments(
      filter: filter,
      fromDate: fromDate,
      toDate: toDate,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<PaymentRegisterEntry>> searchPayments(
    String query, {
    PaymentRegisterFilter filter = PaymentRegisterFilter.all,
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
    int offset = 0,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return fetchPayments(
        filter: filter,
        fromDate: fromDate,
        toDate: toDate,
        limit: limit,
        offset: offset,
      );
    }

    return _queryPayments(
      filter: filter,
      fromDate: fromDate,
      toDate: toDate,
      search: trimmed,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<PaymentRegisterEntry>> _queryPayments({
    required PaymentRegisterFilter filter,
    DateTime? fromDate,
    DateTime? toDate,
    String? search,
    int? limit,
    int offset = 0,
  }) async {
    final businessId = await _businessId();
    if (businessId == null) return [];

    final where = StringBuffer(
      '''
      t.${TransactionsTable.businessId} = ?
        AND t.${TransactionsTable.deletedAt} IS NULL
        AND t.${TransactionsTable.type} IN (?, ?)
      ''',
    );
    final args = <Object?>[
      businessId,
      TransactionTypes.paymentReceived,
      TransactionTypes.paymentPaid,
    ];

    if (filter == PaymentRegisterFilter.received) {
      where.write(' AND t.${TransactionsTable.type} = ?');
      args.add(TransactionTypes.paymentReceived);
    } else if (filter == PaymentRegisterFilter.paid) {
      where.write(' AND t.${TransactionsTable.type} = ?');
      args.add(TransactionTypes.paymentPaid);
    }

    if (fromDate != null) {
      where.write(' AND t.${TransactionsTable.date} >= ?');
      args.add(DateFormatter.isoDate(fromDate));
    }
    if (toDate != null) {
      where.write(' AND t.${TransactionsTable.date} <= ?');
      args.add(DateFormatter.isoDate(toDate));
    }

    if (search != null) {
      final pattern = '%$search%';
      where.write(
        '''
         AND (p.${PartiesTable.name} LIKE ?
           OR p.${PartiesTable.phone} LIKE ?
           OR t.${TransactionsTable.date} LIKE ?
           OR CAST(t.${TransactionsTable.totalAmount} AS TEXT) LIKE ?
           OR IFNULL(t.${TransactionsTable.notes}, '') LIKE ?)
        ''',
      );
      args.addAll([pattern, pattern, pattern, pattern, pattern]);
    }

    final rows = await _db.rawQuery(
      '''
      SELECT
        t.${TransactionsTable.id} AS id,
        t.${TransactionsTable.type} AS type,
        t.${TransactionsTable.partyId} AS party_id,
        t.${TransactionsTable.date} AS date,
        t.${TransactionsTable.createdAt} AS created_at,
        t.${TransactionsTable.totalAmount} AS amount,
        t.${TransactionsTable.notes} AS notes,
        t.${TransactionsTable.reminderDate} AS reminder_date,
        p.${PartiesTable.name} AS party_name,
        p.${PartiesTable.phone} AS party_phone
      FROM ${TransactionsTable.tableName} t
      INNER JOIN ${PartiesTable.tableName} p ON t.${TransactionsTable.partyId} = p.${PartiesTable.id}
      WHERE $where
      ORDER BY t.${TransactionsTable.date} DESC, t.${TransactionsTable.createdAt} DESC
      LIMIT ? OFFSET ?
      ''',
      [...args, limit ?? AppConstants.registerListLimit, offset],
    );

    return rows.map(_mapRow).toList();
  }

  Future<PaymentRegisterEntry?> fetchPayment(String id) async {
    final rows = await _db.rawQuery(
      '''
      SELECT
        t.${TransactionsTable.id} AS id,
        t.${TransactionsTable.type} AS type,
        t.${TransactionsTable.partyId} AS party_id,
        t.${TransactionsTable.date} AS date,
        t.${TransactionsTable.createdAt} AS created_at,
        t.${TransactionsTable.totalAmount} AS amount,
        t.${TransactionsTable.notes} AS notes,
        t.${TransactionsTable.reminderDate} AS reminder_date,
        p.${PartiesTable.name} AS party_name,
        p.${PartiesTable.phone} AS party_phone
      FROM ${TransactionsTable.tableName} t
      INNER JOIN ${PartiesTable.tableName} p ON t.${TransactionsTable.partyId} = p.${PartiesTable.id}
      WHERE t.${TransactionsTable.id} = ? AND t.${TransactionsTable.deletedAt} IS NULL
      ''',
      [id],
    );
    if (rows.isEmpty) return null;
    return _mapRow(rows.first);
  }

  PaymentRegisterEntry _mapRow(Map<String, Object?> row) {
    return PaymentRegisterEntry(
      id: row['id']! as String,
      type: row['type']! as String,
      partyId: row['party_id']! as String,
      partyName: row['party_name']! as String,
      partyPhone: row['party_phone'] as String? ?? '',
      amount: (row['amount'] as num?)?.toDouble() ?? 0,
      date: DateTime.parse(row['date']! as String),
      createdAt: DateTime.parse(row['created_at']! as String),
      note: row['notes'] as String?,
      reminderDate: ReminderService.parseReminderDate(
        row['reminder_date'] as String?,
      ),
    );
  }
}
