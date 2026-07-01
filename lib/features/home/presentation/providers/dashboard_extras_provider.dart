import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/data_revision.dart';
import '../../../items/domain/entities/item.dart';
import '../../../items/presentation/providers/item_providers.dart';
import '../../../reports/data/datasources/transaction_history_local_datasource.dart';
import '../../../reports/presentation/providers/history_providers.dart';

/// Items at or below this quantity are shown in the low-stock section.
const dashboardLowStockThreshold = 5.0;

/// Recent register entries for the dashboard (last five, any date).
final dashboardRecentActivityProvider =
    FutureProvider<List<TransactionHistoryEntry>>((ref) async {
  ref.watch(dataRevisionProvider);

  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 365));
  final entries = await ref.watch(transactionHistoryDataSourceProvider).fetchHistory(
        start: start,
        end: now,
      );
  return entries.take(5).toList();
});

/// Active items with low stock — hidden when empty.
final dashboardLowStockProvider = FutureProvider<List<Item>>((ref) async {
  final items = await ref.watch(itemListProvider.future);
  final lowStock = items
      .where((item) => item.isActive && item.openingStock <= dashboardLowStockThreshold)
      .toList()
    ..sort((a, b) => a.openingStock.compareTo(b.openingStock));
  return lowStock;
});
