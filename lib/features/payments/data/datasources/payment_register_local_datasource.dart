import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../../../../core/accounting/transaction_types.dart';
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
        p.${PartiesTable.name} AS party_name,
        p.${PartiesTable.phone} AS party_phone
      FROM ${TransactionsTable.tableName} t
      INNER JOIN ${PartiesTable.tableName} p ON t.${TransactionsTable.partyId} = p.${PartiesTable.id}
      WHERE $where
      ORDER BY t.${TransactionsTable.createdAt} DESC
      ''',
      args,
    );

    return rows.map(_mapRow).toList();
  }

  Future<List<PaymentRegisterEntry>> searchPayments(String query) async {
    final businessId = await _businessId();
    if (businessId == null) return [];

    final trimmed = query.trim();
    if (trimmed.isEmpty) return fetchPayments();

    final pattern = '%$trimmed%';
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
        p.${PartiesTable.name} AS party_name,
        p.${PartiesTable.phone} AS party_phone
      FROM ${TransactionsTable.tableName} t
      INNER JOIN ${PartiesTable.tableName} p ON t.${TransactionsTable.partyId} = p.${PartiesTable.id}
      WHERE t.${TransactionsTable.businessId} = ?
        AND t.${TransactionsTable.deletedAt} IS NULL
        AND t.${TransactionsTable.type} IN (?, ?)
        AND (p.${PartiesTable.name} LIKE ?
          OR p.${PartiesTable.phone} LIKE ?
          OR t.${TransactionsTable.date} LIKE ?
          OR CAST(t.${TransactionsTable.totalAmount} AS TEXT) LIKE ?)
      ORDER BY t.${TransactionsTable.createdAt} DESC
      ''',
      [
        businessId,
        TransactionTypes.paymentReceived,
        TransactionTypes.paymentPaid,
        pattern,
        pattern,
        pattern,
        pattern,
      ],
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
    );
  }
}
