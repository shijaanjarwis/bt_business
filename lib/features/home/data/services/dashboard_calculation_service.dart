import 'package:sqflite/sqflite.dart';

import '../../../../core/accounting/account_types.dart';
import '../../../../core/accounting/transaction_types.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../data/local/database/tables/accounting_tables.dart';
import '../../domain/entities/dashboard_core_metrics.dart';

/// Computes dashboard totals from transactions and journal lines.
///
/// Values are never persisted — every read runs fresh SQL against active rows.
final class DashboardCalculationService {
  const DashboardCalculationService();

  Future<DashboardCoreMetrics> calculateCoreMetrics({
    required Database db,
    required String businessId,
    DateTime? asOf,
    double openingCash = 0,
  }) async {
    final date = DateFormatter.isoDate(asOf ?? DateTime.now());

    final aajKiBikri = await calculateAajKiBikri(
      db: db,
      businessId: businessId,
      date: date,
    );
    final aajCashMila = await calculateAajCashMila(
      db: db,
      businessId: businessId,
      date: date,
    );
    final aajUdhaarBana = await calculateAajUdhaarBana(
      db: db,
      businessId: businessId,
      date: date,
    );
    final cashInHand = await calculateCashInHand(
      db: db,
      businessId: businessId,
      openingCash: openingCash,
    );

    return DashboardCoreMetrics(
      aajKiBikri: aajKiBikri,
      aajCashMila: aajCashMila,
      aajUdhaarBana: aajUdhaarBana,
      cashInHand: cashInHand,
    );
  }

  /// Aaj ki Bikri — sum of [TransactionsTable.totalAmount] for today's sales.
  Future<double> calculateAajKiBikri({
    required Database db,
    required String businessId,
    required String date,
  }) {
    return _sumTransactions(
      db: db,
      businessId: businessId,
      type: TransactionTypes.sale,
      date: date,
      column: TransactionsTable.totalAmount,
    );
  }

  /// Aaj Cash Mila — every cash debit on today's active transactions.
  ///
  /// Includes sale payments, jama on old bills, and any other incoming cash.
  Future<double> calculateAajCashMila({
    required Database db,
    required String businessId,
    required String date,
  }) {
    return _readDouble(
      db,
      '''
        SELECT COALESCE(SUM(jl.${JournalLinesTable.debit}), 0)
        FROM ${JournalLinesTable.tableName} jl
        INNER JOIN ${TransactionsTable.tableName} t
          ON jl.${JournalLinesTable.transactionId} = t.${TransactionsTable.id}
        INNER JOIN ${AccountsTable.tableName} a
          ON jl.${JournalLinesTable.accountId} = a.${AccountsTable.id}
        WHERE a.${AccountsTable.businessId} = ?
          AND a.${AccountsTable.type} = ?
          AND t.${TransactionsTable.date} = ?
          AND jl.${JournalLinesTable.debit} > 0
          AND t.${TransactionsTable.deletedAt} IS NULL
          AND jl.${JournalLinesTable.deletedAt} IS NULL
        ''',
      [businessId, AccountTypes.cash, date],
    );
  }

  /// Aaj Udhaar Bana — sum of [TransactionsTable.dueAmount] for today's sales.
  Future<double> calculateAajUdhaarBana({
    required Database db,
    required String businessId,
    required String date,
  }) {
    return _sumTransactions(
      db: db,
      businessId: businessId,
      type: TransactionTypes.sale,
      date: date,
      column: TransactionsTable.dueAmount,
    );
  }

  /// Cash in Hand — net cash journal balance plus optional opening cash.
  ///
  /// Cash received (debits) minus cash paid (credits) across all active lines.
  Future<double> calculateCashInHand({
    required Database db,
    required String businessId,
    double openingCash = 0,
  }) async {
    final netCash = await _readDouble(
      db,
      '''
        SELECT COALESCE(SUM(jl.${JournalLinesTable.debit} - jl.${JournalLinesTable.credit}), 0)
        FROM ${JournalLinesTable.tableName} jl
        INNER JOIN ${AccountsTable.tableName} a
          ON jl.${JournalLinesTable.accountId} = a.${AccountsTable.id}
        WHERE a.${AccountsTable.businessId} = ?
          AND a.${AccountsTable.type} = ?
          AND jl.${JournalLinesTable.deletedAt} IS NULL
        ''',
      [businessId, AccountTypes.cash],
    );
    return netCash + openingCash;
  }

  Future<double> _sumTransactions({
    required Database db,
    required String businessId,
    required String type,
    required String date,
    required String column,
  }) {
    return _readDouble(
      db,
      '''
        SELECT COALESCE(SUM(t.$column), 0)
        FROM ${TransactionsTable.tableName} t
        WHERE t.${TransactionsTable.businessId} = ?
          AND t.${TransactionsTable.type} = ?
          AND t.${TransactionsTable.date} = ?
          AND t.${TransactionsTable.deletedAt} IS NULL
        ''',
      [businessId, type, date],
    );
  }

  Future<double> _readDouble(Database db, String sql, List<Object?> args) async {
    final rows = await db.rawQuery(sql, args);
    if (rows.isEmpty) return 0;
    final value = rows.first.values.first;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
