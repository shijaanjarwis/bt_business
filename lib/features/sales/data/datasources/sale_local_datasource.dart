import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../../../../core/accounting/payment_modes.dart';
import '../../../../core/accounting/transaction_types.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../data/local/database/tables/accounting_tables.dart';
import '../../../../features/business/data/datasources/business_table.dart';
import '../../domain/entities/sale_entry.dart';
import '../models/sale_entry_model.dart';

/// SQLite read operations for sale register entries.
final class SaleLocalDataSource {
  const SaleLocalDataSource(this._db);

  final Database _db;

  Future<String?> currentBusinessId() async {
    final rows = await _db.query(BusinessTable.tableName, limit: 1);
    if (rows.isEmpty) return null;
    return rows.first[BusinessTable.id] as String;
  }

  Future<List<SaleEntry>> fetchSales({
    DateTime? fromDate,
    DateTime? toDate,
    PaymentMode? paymentMode,
  }) async {
    final businessId = await currentBusinessId();
    if (businessId == null) return [];

    final where = StringBuffer(
      't.${TransactionsTable.businessId} = ? AND t.${TransactionsTable.type} = ?',
    );
    final args = <Object?>[businessId, TransactionTypes.sale];

    if (fromDate != null) {
      where.write(' AND t.${TransactionsTable.date} >= ?');
      args.add(DateFormatter.isoDate(fromDate));
    }
    if (toDate != null) {
      where.write(' AND t.${TransactionsTable.date} <= ?');
      args.add(DateFormatter.isoDate(toDate));
    }
    if (paymentMode != null) {
      where.write(' AND t.${TransactionsTable.paymentMode} = ?');
      args.add(paymentMode.code);
    }

    final rows = await _db.rawQuery(
      '''
      SELECT t.*, p.${PartiesTable.name} AS party_name
      FROM ${TransactionsTable.tableName} t
      INNER JOIN ${PartiesTable.tableName} p ON t.${TransactionsTable.partyId} = p.${PartiesTable.id}
      WHERE $where
      ORDER BY t.${TransactionsTable.date} DESC, t.${TransactionsTable.createdAt} DESC
      ''',
      args,
    );

    return _mapEntries(rows);
  }

  Future<List<SaleEntry>> searchSales(String query) async {
    final businessId = await currentBusinessId();
    if (businessId == null) return [];

    final trimmed = query.trim();
    if (trimmed.isEmpty) return fetchSales();

    final pattern = '%$trimmed%';
    final rows = await _db.rawQuery(
      '''
      SELECT t.*, p.${PartiesTable.name} AS party_name
      FROM ${TransactionsTable.tableName} t
      INNER JOIN ${PartiesTable.tableName} p ON t.${TransactionsTable.partyId} = p.${PartiesTable.id}
      WHERE t.${TransactionsTable.businessId} = ?
        AND t.${TransactionsTable.type} = ?
        AND (p.${PartiesTable.name} LIKE ?
          OR p.${PartiesTable.phone} LIKE ?)
      ORDER BY t.${TransactionsTable.date} DESC, t.${TransactionsTable.createdAt} DESC
      ''',
      [businessId, TransactionTypes.sale, pattern, pattern],
    );

    return _mapEntries(rows);
  }

  Future<SaleEntry?> fetchSale(String id) async {
    final rows = await _db.rawQuery(
      '''
      SELECT t.*, p.${PartiesTable.name} AS party_name
      FROM ${TransactionsTable.tableName} t
      INNER JOIN ${PartiesTable.tableName} p ON t.${TransactionsTable.partyId} = p.${PartiesTable.id}
      WHERE t.${TransactionsTable.id} = ?
      ''',
      [id],
    );
    if (rows.isEmpty) return null;

    final lines = await _fetchLines(id);
    return SaleEntryModel.fromJoinedMap(rows.first, lines: lines).entry;
  }

  Future<List<SaleEntry>> _mapEntries(List<Map<String, Object?>> rows) async {
    final entries = <SaleEntry>[];
    for (final row in rows) {
      final id = row[TransactionsTable.id]! as String;
      final lines = await _fetchLines(id);
      entries.add(SaleEntryModel.fromJoinedMap(row, lines: lines).entry);
    }
    return entries;
  }

  Future<List<SaleLine>> _fetchLines(String transactionId) async {
    final rows = await _db.query(
      TransactionLinesTable.tableName,
      where: '${TransactionLinesTable.transactionId} = ?',
      whereArgs: [transactionId],
      orderBy: '${TransactionLinesTable.sortOrder} ASC',
    );
    return rows.map(SaleEntryModel.lineFromMap).toList();
  }
}
