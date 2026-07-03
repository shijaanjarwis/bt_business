import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../../../../core/accounting/account_types.dart';
import '../../../../core/accounting/transaction_types.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../data/local/database/tables/accounting_tables.dart';
import '../../../business/data/datasources/business_table.dart';
import '../../domain/entities/dashboard_summary_entry.dart';

/// Cash movement and cash-in rows for dashboard summary detail screens.
final class DashboardSummaryLocalDataSource {
  const DashboardSummaryLocalDataSource(this._db);

  final Database _db;

  Future<List<DashboardSummaryEntry>> fetchCashReceived({
    required DateTime fromDate,
    required DateTime toDate,
    String? searchQuery,
    int? limit,
  }) async {
    return _fetchCashMovements(
      fromDate: fromDate,
      toDate: toDate,
      searchQuery: searchQuery,
      cashInOnly: true,
      limit: limit,
    );
  }

  Future<List<DashboardSummaryEntry>> fetchCashLedger({
    required DateTime fromDate,
    required DateTime toDate,
    String? searchQuery,
    int? limit,
  }) async {
    return _fetchCashMovements(
      fromDate: fromDate,
      toDate: toDate,
      searchQuery: searchQuery,
      cashInOnly: false,
      limit: limit,
    );
  }

  Future<List<DashboardSummaryEntry>> _fetchCashMovements({
    required DateTime fromDate,
    required DateTime toDate,
    String? searchQuery,
    required bool cashInOnly,
    int? limit,
  }) async {
    try {
      final businessId = await _currentBusinessId();
      if (businessId == null) return [];

      final where = StringBuffer('''
        a.${AccountsTable.businessId} = ?
          AND a.${AccountsTable.type} = ?
          AND t.${TransactionsTable.deletedAt} IS NULL
          AND jl.${JournalLinesTable.deletedAt} IS NULL
          AND t.${TransactionsTable.date} >= ?
          AND t.${TransactionsTable.date} <= ?
      ''');
      final args = <Object?>[
        businessId,
        AccountTypes.cash,
        DateFormatter.isoDate(fromDate),
        DateFormatter.isoDate(toDate),
      ];

      if (cashInOnly) {
        where.write(' AND jl.${JournalLinesTable.debit} > 0');
      } else {
        where.write(
          ' AND (jl.${JournalLinesTable.debit} > 0 OR jl.${JournalLinesTable.credit} > 0)',
        );
      }

      final trimmed = searchQuery?.trim() ?? '';
      if (trimmed.isNotEmpty) {
        final pattern = '%$trimmed%';
        where.write('''
          AND (
            IFNULL(p.${PartiesTable.name}, '') LIKE ?
            OR IFNULL(t.${TransactionsTable.notes}, '') LIKE ?
            OR CAST(jl.${JournalLinesTable.debit} AS TEXT) LIKE ?
            OR CAST(jl.${JournalLinesTable.credit} AS TEXT) LIKE ?
            OR CAST(t.${TransactionsTable.totalAmount} AS TEXT) LIKE ?
            OR EXISTS (
              SELECT 1 FROM ${TransactionLinesTable.tableName} tl
              WHERE tl.${TransactionLinesTable.transactionId} = t.${TransactionsTable.id}
                AND tl.${TransactionLinesTable.deletedAt} IS NULL
                AND tl.${TransactionLinesTable.itemName} LIKE ?
            )
          )
        ''');
        args.addAll([pattern, pattern, pattern, pattern, pattern, pattern]);
      }

      final rows = await _db.rawQuery(
        '''
        SELECT
          t.${TransactionsTable.id} AS id,
          t.${TransactionsTable.type} AS type,
          t.${TransactionsTable.date} AS date,
          t.${TransactionsTable.createdAt} AS created_at,
          t.${TransactionsTable.notes} AS notes,
          t.${TransactionsTable.totalAmount} AS total_amount,
          IFNULL(p.${PartiesTable.name}, '') AS party_name,
          jl.${JournalLinesTable.debit} AS cash_debit,
          jl.${JournalLinesTable.credit} AS cash_credit
        FROM ${JournalLinesTable.tableName} jl
        INNER JOIN ${AccountsTable.tableName} a
          ON jl.${JournalLinesTable.accountId} = a.${AccountsTable.id}
        INNER JOIN ${TransactionsTable.tableName} t
          ON jl.${JournalLinesTable.transactionId} = t.${TransactionsTable.id}
        LEFT JOIN ${PartiesTable.tableName} p
          ON t.${TransactionsTable.partyId} = p.${PartiesTable.id}
        WHERE $where
        ORDER BY t.${TransactionsTable.date} DESC, t.${TransactionsTable.createdAt} DESC
        LIMIT ?
        ''',
        [...args, limit ?? AppConstants.registerListLimit],
      );

      return rows.map(_mapCashRow).toList();
    } catch (error) {
      throw DatabaseException('Failed to load cash summary rows: $error');
    }
  }

  DashboardSummaryEntry _mapCashRow(Map<String, Object?> row) {
    final type = row['type']! as String;
    final debit = (row['cash_debit'] as num?)?.toDouble() ?? 0;
    final credit = (row['cash_credit'] as num?)?.toDouble() ?? 0;
    final isCashOut = credit > debit;
    final amount = isCashOut ? credit : debit;
    final partyName = (row['party_name'] as String?)?.trim() ?? '';
    final notes = (row['notes'] as String?)?.trim();

    return DashboardSummaryEntry(
      id: row['id']! as String,
      transactionType: type,
      title: partyName.isNotEmpty ? partyName : _typeLabel(type, notes),
      amount: amount,
      date: DateTime.parse(row['date']! as String),
      createdAt: DateTime.parse(row['created_at']! as String),
      subtitle: _subtitle(type, notes, isCashOut),
      isCashOut: isCashOut,
      isReceive: type == TransactionTypes.paymentReceived,
    );
  }

  String _typeLabel(String type, String? notes) {
    return switch (type) {
      TransactionTypes.sale => 'Bikri',
      TransactionTypes.purchase => 'Kharid',
      TransactionTypes.paymentReceived => 'Paisa Mila',
      TransactionTypes.paymentPaid => 'Paisa Diya',
      TransactionTypes.expense => notes?.split('\n').first.trim().isNotEmpty == true
          ? notes!.split('\n').first.trim()
          : 'Kharch',
      _ => 'Cash',
    };
  }

  String? _subtitle(String type, String? notes, bool isCashOut) {
    final direction = isCashOut ? 'Cash Out' : 'Cash In';
    final typeLabel = switch (type) {
      TransactionTypes.sale => 'Bikri',
      TransactionTypes.purchase => 'Kharid',
      TransactionTypes.paymentReceived => 'Jama',
      TransactionTypes.paymentPaid => 'Payment',
      TransactionTypes.expense => 'Kharch',
      _ => type,
    };
    final noteText = notes?.trim();
    if (noteText != null && noteText.isNotEmpty) {
      return '$direction · $typeLabel · $noteText';
    }
    return '$direction · $typeLabel';
  }

  Future<String?> _currentBusinessId() async {
    final rows = await _db.query(BusinessTable.tableName, limit: 1);
    if (rows.isEmpty) return null;
    return rows.first[BusinessTable.id] as String;
  }
}
