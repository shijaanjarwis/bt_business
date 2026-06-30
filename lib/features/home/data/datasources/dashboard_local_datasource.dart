import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../../../../core/accounting/account_types.dart';
import '../../../../core/accounting/transaction_types.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../data/local/database/tables/accounting_tables.dart';
import '../../../../features/business/data/datasources/business_table.dart';
import '../../domain/entities/dashboard_summary.dart';

/// Aggregates dashboard metrics from SQLite ledger tables.
final class DashboardLocalDataSource {
  const DashboardLocalDataSource(this._db);

  final Database _db;

  Future<DashboardSummary> fetchSummary({DateTime? asOf}) async {
    try {
      final businessId = await _currentBusinessId();
      if (businessId == null) return DashboardSummary.zero;

      final date = DateFormatter.isoDate(asOf ?? DateTime.now());

      final todaysSales = await _sumTransactions(
        businessId: businessId,
        type: TransactionTypes.sale,
        date: date,
      );
      final todaysPurchase = await _sumTransactions(
        businessId: businessId,
        type: TransactionTypes.purchase,
        date: date,
      );
      final todaysExpenses = await _sumTransactions(
        businessId: businessId,
        type: TransactionTypes.expense,
        date: date,
      );
      final paymentReceived = await _sumTransactions(
        businessId: businessId,
        type: TransactionTypes.paymentReceived,
        date: date,
      );
      final paymentPaid = await _sumTransactions(
        businessId: businessId,
        type: TransactionTypes.paymentPaid,
        date: date,
      );

      final cashInHand = await _accountBalance(
        businessId: businessId,
        accountType: AccountTypes.cash,
      );
      final amountInBank = await _accountBalance(
        businessId: businessId,
        accountType: AccountTypes.bank,
      );

      final receivables = await _partyBalances(
        businessId: businessId,
        receivable: true,
      );
      final payables = await _partyBalances(
        businessId: businessId,
        receivable: false,
      );

      final goodsSold = await _sumStockMovements(
        businessId: businessId,
        date: date,
        sold: true,
      );
      final goodsPurchased = await _sumStockMovements(
        businessId: businessId,
        date: date,
        sold: false,
      );
      final stockValue = await _stockValue(businessId: businessId);

      return DashboardSummary(
        todaysProfit: todaysSales - todaysPurchase - todaysExpenses,
        todaysSales: todaysSales,
        todaysPurchase: todaysPurchase,
        cashInHand: cashInHand,
        amountInBank: amountInBank,
        todaysReceivables: receivables.total,
        todaysPayables: payables.total,
        paymentReceived: paymentReceived,
        paymentPaid: paymentPaid,
        goodsSold: goodsSold,
        goodsPurchased: goodsPurchased,
        stockValue: stockValue,
        receivableCount: receivables.count,
        payableCount: payables.count,
      );
    } catch (error) {
      throw DatabaseException('Failed to load dashboard summary: $error');
    }
  }

  Future<String?> _currentBusinessId() async {
    final rows = await _db.query(BusinessTable.tableName, limit: 1);
    if (rows.isEmpty) return null;
    return rows.first[BusinessTable.id] as String;
  }

  Future<double> _readDouble(String sql, List<Object?> args) async {
    final rows = await _db.rawQuery(sql, args);
    if (rows.isEmpty) return 0;
    final value = rows.first.values.first;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  Future<double> _sumTransactions({
    required String businessId,
    required String type,
    required String date,
  }) async {
    return _readDouble(
      '''
        SELECT COALESCE(SUM(${TransactionsTable.totalAmount}), 0)
        FROM ${TransactionsTable.tableName}
        WHERE ${TransactionsTable.businessId} = ?
          AND ${TransactionsTable.type} = ?
          AND ${TransactionsTable.date} = ?
        ''',
      [businessId, type, date],
    );
  }

  Future<double> _accountBalance({
    required String businessId,
    required String accountType,
  }) async {
    return _readDouble(
      '''
        SELECT COALESCE(SUM(jl.${JournalLinesTable.debit} - jl.${JournalLinesTable.credit}), 0)
        FROM ${JournalLinesTable.tableName} jl
        INNER JOIN ${AccountsTable.tableName} a
          ON jl.${JournalLinesTable.accountId} = a.${AccountsTable.id}
        WHERE a.${AccountsTable.businessId} = ?
          AND a.${AccountsTable.type} = ?
        ''',
      [businessId, accountType],
    );
  }

  Future<({double total, int count})> _partyBalances({
    required String businessId,
    required bool receivable,
  }) async {
    final operator = receivable ? '>' : '<';
    final total = await _readDouble(
      '''
        SELECT COALESCE(SUM(ABS(${PartiesTable.balance})), 0)
        FROM ${PartiesTable.tableName}
        WHERE ${PartiesTable.businessId} = ?
          AND ${PartiesTable.balance} $operator 0
          AND ${PartiesTable.isActive} = 1
        ''',
      [businessId],
    );
    final count = Sqflite.firstIntValue(
      await _db.rawQuery(
        '''
        SELECT COUNT(*)
        FROM ${PartiesTable.tableName}
        WHERE ${PartiesTable.businessId} = ?
          AND ${PartiesTable.balance} $operator 0
          AND ${PartiesTable.isActive} = 1
        ''',
        [businessId],
      ),
    );
    return (total: total, count: count ?? 0);
  }

  Future<double> _sumStockMovements({
    required String businessId,
    required String date,
    required bool sold,
  }) async {
    final qtyFilter = sold
        ? 'sm.${StockMovementsTable.qtyDelta} < 0'
        : 'sm.${StockMovementsTable.qtyDelta} > 0';

    return _readDouble(
      '''
        SELECT COALESCE(SUM(ABS(sm.${StockMovementsTable.qtyDelta}) * sm.${StockMovementsTable.rate}), 0)
        FROM ${StockMovementsTable.tableName} sm
        INNER JOIN ${ItemsTable.tableName} i
          ON sm.${StockMovementsTable.itemId} = i.${ItemsTable.id}
        WHERE i.${ItemsTable.businessId} = ?
          AND sm.${StockMovementsTable.movementDate} = ?
          AND $qtyFilter
        ''',
      [businessId, date],
    );
  }

  Future<double> _stockValue({required String businessId}) async {
    return _readDouble(
      '''
        SELECT COALESCE(SUM(${ItemsTable.qtyOnHand} * ${ItemsTable.purchaseRate}), 0)
        FROM ${ItemsTable.tableName}
        WHERE ${ItemsTable.businessId} = ?
        ''',
      [businessId],
    );
  }
}
