import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../../../../core/accounting/payment_modes.dart';
import '../../../../core/accounting/transaction_types.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../data/local/database/tables/accounting_tables.dart';
import '../../../../features/business/data/datasources/business_table.dart';
import '../../domain/entities/sale_entry.dart';
import '../models/sale_entry_model.dart';

/// SQLite read operations for sale register entries.
final class SaleLocalDataSource {
  const SaleLocalDataSource(this._db, {this.businessId});

  final Database _db;
  final String? businessId;

  Future<String?> currentBusinessId() async {
    if (businessId != null) return businessId;
    final rows = await _db.query(BusinessTable.tableName, limit: 1);
    if (rows.isEmpty) return null;
    return rows.first[BusinessTable.id] as String;
  }

  Future<List<SaleEntry>> fetchSales({
    DateTime? fromDate,
    DateTime? toDate,
    PaymentMode? paymentMode,
    double? minDueAmount,
    double? minPaidAmount,
    int? limit,
    int offset = 0,
  }) async {
    final resolvedBusinessId = await currentBusinessId();
    if (resolvedBusinessId == null) return [];

    final where = StringBuffer(
      't.${TransactionsTable.businessId} = ? AND t.${TransactionsTable.type} = ? AND t.${TransactionsTable.deletedAt} IS NULL',
    );
    final args = <Object?>[resolvedBusinessId, TransactionTypes.sale];

    _appendFilters(
      where: where,
      args: args,
      fromDate: fromDate,
      toDate: toDate,
      paymentMode: paymentMode,
      minDueAmount: minDueAmount,
      minPaidAmount: minPaidAmount,
    );

    final rows = await _db.rawQuery(
      '''
      SELECT t.*, p.${PartiesTable.name} AS party_name
      FROM ${TransactionsTable.tableName} t
      INNER JOIN ${PartiesTable.tableName} p ON t.${TransactionsTable.partyId} = p.${PartiesTable.id}
      WHERE $where
      ORDER BY t.${TransactionsTable.date} DESC, t.${TransactionsTable.createdAt} DESC
      LIMIT ? OFFSET ?
      ''',
      [...args, limit ?? AppConstants.registerListLimit, offset],
    );

    return _mapHeaders(rows);
  }

  Future<List<SaleEntry>> searchSales(
    String query, {
    DateTime? fromDate,
    DateTime? toDate,
    PaymentMode? paymentMode,
    double? minDueAmount,
    double? minPaidAmount,
    int? limit,
    int offset = 0,
  }) async {
    final resolvedBusinessId = await currentBusinessId();
    if (resolvedBusinessId == null) return [];

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return fetchSales(
        fromDate: fromDate,
        toDate: toDate,
        paymentMode: paymentMode,
        minDueAmount: minDueAmount,
        minPaidAmount: minPaidAmount,
        limit: limit,
        offset: offset,
      );
    }

    final pattern = '%$trimmed%';
    final where = StringBuffer(
      '''
      t.${TransactionsTable.businessId} = ?
        AND t.${TransactionsTable.type} = ?
        AND t.${TransactionsTable.deletedAt} IS NULL
        AND (p.${PartiesTable.name} LIKE ?
          OR p.${PartiesTable.phone} LIKE ?
          OR t.${TransactionsTable.date} LIKE ?
          OR CAST(t.${TransactionsTable.totalAmount} AS TEXT) LIKE ?
          OR IFNULL(t.${TransactionsTable.notes}, '') LIKE ?
          OR EXISTS (
            SELECT 1 FROM ${TransactionLinesTable.tableName} tl
            WHERE tl.${TransactionLinesTable.transactionId} = t.${TransactionsTable.id}
              AND tl.${TransactionLinesTable.deletedAt} IS NULL
              AND tl.${TransactionLinesTable.itemName} LIKE ?
          ))
      ''',
    );
    final args = <Object?>[resolvedBusinessId, TransactionTypes.sale];

    _appendFilters(
      where: where,
      args: args,
      fromDate: fromDate,
      toDate: toDate,
      paymentMode: paymentMode,
      minDueAmount: minDueAmount,
      minPaidAmount: minPaidAmount,
    );

    args
      ..add(pattern)
      ..add(pattern)
      ..add(pattern)
      ..add(pattern)
      ..add(pattern)
      ..add(pattern);

    final rows = await _db.rawQuery(
      '''
      SELECT t.*, p.${PartiesTable.name} AS party_name
      FROM ${TransactionsTable.tableName} t
      INNER JOIN ${PartiesTable.tableName} p ON t.${TransactionsTable.partyId} = p.${PartiesTable.id}
      WHERE $where
      ORDER BY t.${TransactionsTable.date} DESC, t.${TransactionsTable.createdAt} DESC
      LIMIT ? OFFSET ?
      ''',
      [...args, limit ?? AppConstants.registerListLimit, offset],
    );

    return _mapHeaders(rows);
  }

  Future<SaleEntry?> fetchSale(String id) async {
    final rows = await _db.rawQuery(
      '''
      SELECT t.*, p.${PartiesTable.name} AS party_name
      FROM ${TransactionsTable.tableName} t
      INNER JOIN ${PartiesTable.tableName} p ON t.${TransactionsTable.partyId} = p.${PartiesTable.id}
      WHERE t.${TransactionsTable.id} = ? AND t.${TransactionsTable.deletedAt} IS NULL
      ''',
      [id],
    );
    if (rows.isEmpty) return null;

    final lines = await _fetchLines(id);
    return SaleEntryModel.fromJoinedMap(rows.first, lines: lines).entry;
  }

  List<SaleEntry> _mapHeaders(List<Map<String, Object?>> rows) {
    return rows
        .map(
          (row) => SaleEntryModel.fromJoinedMap(row, lines: const []).entry,
        )
        .toList();
  }

  void _appendFilters({
    required StringBuffer where,
    required List<Object?> args,
    DateTime? fromDate,
    DateTime? toDate,
    PaymentMode? paymentMode,
    double? minDueAmount,
    double? minPaidAmount,
  }) {
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
    if (minDueAmount != null) {
      where.write(' AND t.${TransactionsTable.dueAmount} >= ?');
      args.add(minDueAmount);
    }
    if (minPaidAmount != null) {
      where.write(' AND t.${TransactionsTable.paidAmount} >= ?');
      args.add(minPaidAmount);
    }
  }

  Future<List<SaleLine>> _fetchLines(String transactionId) async {
    final rows = await _db.query(
      TransactionLinesTable.tableName,
      where:
          '${TransactionLinesTable.transactionId} = ? AND ${TransactionLinesTable.deletedAt} IS NULL',
      whereArgs: [transactionId],
      orderBy: '${TransactionLinesTable.sortOrder} ASC',
    );
    return rows.map(SaleEntryModel.lineFromMap).toList();
  }
}
