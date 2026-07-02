import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../../../../core/accounting/payment_modes.dart';
import '../../../../core/accounting/transaction_types.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../data/local/database/tables/accounting_tables.dart';
import '../../../../features/business/data/datasources/business_table.dart';
import '../../../../features/sales/data/models/sale_item_model.dart';
import '../../domain/entities/purchase_invoice.dart';
import '../models/purchase_invoice_model.dart';

/// SQLite read/write operations for purchase invoices and catalog items.
final class PurchaseLocalDataSource {
  const PurchaseLocalDataSource(this._db);

  final Database _db;

  Future<String?> currentBusinessId() async {
    final rows = await _db.query(BusinessTable.tableName, limit: 1);
    if (rows.isEmpty) return null;
    return rows.first[BusinessTable.id] as String;
  }

  Future<List<PurchaseInvoice>> fetchPurchases({
    DateTime? fromDate,
    DateTime? toDate,
    PaymentMode? paymentMode,
    double? minDueAmount,
    double? minPaidAmount,
    int? limit,
    int offset = 0,
  }) async {
    final businessId = await currentBusinessId();
    if (businessId == null) return [];

    final where = StringBuffer(
      't.${TransactionsTable.businessId} = ? AND t.${TransactionsTable.type} = ? AND t.${TransactionsTable.deletedAt} IS NULL',
    );
    final args = <Object?>[businessId, TransactionTypes.purchase];

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

  Future<List<PurchaseInvoice>> searchPurchases(
    String query, {
    DateTime? fromDate,
    DateTime? toDate,
    PaymentMode? paymentMode,
    double? minDueAmount,
    double? minPaidAmount,
    int? limit,
    int offset = 0,
  }) async {
    final businessId = await currentBusinessId();
    if (businessId == null) return [];

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return fetchPurchases(
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
        AND (t.${TransactionsTable.invoiceNo} LIKE ?
          OR p.${PartiesTable.name} LIKE ?
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
    final args = <Object?>[businessId, TransactionTypes.purchase];

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
      ..add(pattern)
      ..add(pattern);

    final rows = await _db.rawQuery(
      '''
      SELECT t.*, p.${PartiesTable.name} AS party_name
      FROM ${TransactionsTable.tableName} t
      INNER JOIN ${PartiesTable.tableName} p ON t.${TransactionsTable.partyId} = p.${TransactionsTable.id}
      WHERE $where
      ORDER BY t.${TransactionsTable.date} DESC, t.${TransactionsTable.createdAt} DESC
      LIMIT ? OFFSET ?
      ''',
      [...args, limit ?? AppConstants.registerListLimit, offset],
    );

    return _mapHeaders(rows);
  }

  Future<PurchaseInvoice?> fetchPurchase(String id) async {
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
    return PurchaseInvoiceModel.fromJoinedMap(rows.first, lines: lines).invoice;
  }

  Future<List<SaleItem>> searchItems(String query) async {
    final businessId = await currentBusinessId();
    if (businessId == null) return [];

    final trimmed = query.trim();
    final where = StringBuffer(
      '${ItemsTable.businessId} = ? AND ${ItemsTable.isActive} = 1 AND ${ItemsTable.deletedAt} IS NULL',
    );
    final args = <Object?>[businessId];

    if (trimmed.isNotEmpty) {
      where.write(' AND ${ItemsTable.name} LIKE ?');
      args.add('%$trimmed%');
    }

    final rows = await _db.query(
      ItemsTable.tableName,
      where: where.toString(),
      whereArgs: args,
      orderBy: '${ItemsTable.name} COLLATE NOCASE ASC',
      limit: 50,
    );

    return rows.map((row) => SaleItemModel.fromMap(row).item).toList();
  }

  List<PurchaseInvoice> _mapHeaders(List<Map<String, Object?>> rows) {
    return rows
        .map(
          (row) =>
              PurchaseInvoiceModel.fromJoinedMap(row, lines: const []).invoice,
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

  Future<List<PurchaseLine>> _fetchLines(String transactionId) async {
    final rows = await _db.query(
      TransactionLinesTable.tableName,
      where:
          '${TransactionLinesTable.transactionId} = ? AND ${TransactionLinesTable.deletedAt} IS NULL',
      whereArgs: [transactionId],
      orderBy: '${TransactionLinesTable.sortOrder} ASC',
    );
    return rows.map(PurchaseInvoiceModel.lineFromMap).toList();
  }
}
