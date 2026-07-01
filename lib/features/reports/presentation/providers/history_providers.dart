import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/di/data_revision.dart';
import '../../data/datasources/transaction_history_local_datasource.dart';
import '../../domain/history_models.dart';
import '../utils/history_ui_helpers.dart';

final transactionHistoryDataSourceProvider =
    Provider<TransactionHistoryLocalDataSource>((ref) {
  final database = ref.watch(appDatabaseProvider).requireValue;
  return TransactionHistoryLocalDataSource(database);
});

final historyPeriodProvider = StateProvider<HistoryPeriod>(
  (ref) => HistoryPeriod.today,
);

final historyCustomStartProvider = StateProvider<DateTime?>((ref) => null);
final historyCustomEndProvider = StateProvider<DateTime?>((ref) => null);

final historySearchQueryProvider = StateProvider<String>((ref) => '');

final transactionHistoryProvider = FutureProvider<List<TransactionHistoryEntry>>((ref) async {
  ref.watch(dataRevisionProvider);

  final period = ref.watch(historyPeriodProvider);
  final customStart = ref.watch(historyCustomStartProvider);
  final customEnd = ref.watch(historyCustomEndProvider);

  final range = HistoryDateRange.resolve(
    period: period,
    customStart: customStart,
    customEnd: customEnd,
  );

  return ref.watch(transactionHistoryDataSourceProvider).fetchHistory(
        start: range.start,
        end: range.end,
      );
});

final filteredTransactionHistoryProvider =
    Provider<AsyncValue<List<TransactionHistoryEntry>>>((ref) {
  final historyAsync = ref.watch(transactionHistoryProvider);
  final query = ref.watch(historySearchQueryProvider);

  return historyAsync.whenData((entries) {
    if (query.trim().isEmpty) return entries;
    return entries
        .where((entry) => HistoryUiHelpers.matchesSearch(entry, query))
        .toList();
  });
});

final groupedTransactionHistoryProvider = Provider<
    AsyncValue<
        List<({String header, DateTime day, List<TransactionHistoryEntry> entries})>>>(
  (ref) {
    final filteredAsync = ref.watch(filteredTransactionHistoryProvider);
    return filteredAsync.whenData(HistoryUiHelpers.groupByDate);
  },
);
