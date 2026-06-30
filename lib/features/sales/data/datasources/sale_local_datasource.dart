import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../../../../core/accounting/payment_modes.dart';
import '../../../../core/accounting/transaction_types.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../data/local/database/tables/accounting_tables.dart';
import '../../../../features/business/data/datasources/business_table.dart';
import '../../domain/entities/sale_invoice.dart';
import '../models/sale_invoice_model.dart';
import '../models/sale_item_model.dart';

/// SQLite read/write operations for sales invoices and catalog items.
final class SaleLocalDataSource {
  const SaleLocalDataSource(this._db);

  final Database _db;

  Future<String?> currentBusinessId() async {
    final rows = await _db.query(BusinessTable.tableName, limit: 1);
    if (rows.isEmpty) return null;
    return rows.first[BusinessTable.id] as String;
  }

  Future<List<SaleInvoice>> fetchSales({
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

    return _mapInvoices(rows);
  }

  Future<List<SaleInvoice>> searchSales(String query) async {
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
        AND (t.${TransactionsTable.invoiceNo} LIKE ?
          OR p.${PartiesTable.name} LIKE ?
          OR p.${PartiesTable.phone} LIKE ?)
      ORDER BY t.${TransactionsTable.date} DESC, t.${TransactionsTable.createdAt} DESC
      ''',
      [businessId, TransactionTypes.sale, pattern, pattern, pattern],
    );

    return _mapInvoices(rows);
  }

  Future<SaleInvoice?> fetchSale(String id) async {
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
    return SaleInvoiceModel.fromJoinedMap(rows.first, lines: lines).invoice;
  }

  Future<List<SaleItem>> searchItems(String query) async {
    final businessId = await currentBusinessId();
    if (businessId == null) return [];

    final trimmed = query.trim();
    final where = StringBuffer('${ItemsTable.businessId} = ? AND ${ItemsTable.isActive} = 1');
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

  Future<SaleItem?> fetchItem(String id) async {
    final rows = await _db.query(
      ItemsTable.tableName,
      where: '${ItemsTable.id} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SaleItemModel.fromMap(rows.first).item;
  }

  Future<List<SaleInvoice>> _mapInvoices(List<Map<String, Object?>> rows) async {
    final invoices = <SaleInvoice>[];
    for (final row in rows) {
      final id = row[TransactionsTable.id]! as String;
      final lines = await _fetchLines(id);
      invoices.add(SaleInvoiceModel.fromJoinedMap(row, lines: lines).invoice);
    }
    return invoices;
  }

  Future<List<SaleLine>> _fetchLines(String transactionId) async {
    final rows = await _db.query(
      TransactionLinesTable.tableName,
      where: '${TransactionLinesTable.transactionId} = ?',
      whereArgs: [transactionId],
      orderBy: '${TransactionLinesTable.sortOrder} ASC',
    );
    return rows.map(SaleInvoiceModel.lineFromMap).toList();
  }
}
