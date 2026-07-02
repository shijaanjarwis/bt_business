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
    FutureProvider.autoDispose<List<TransactionHistoryEntry>>((ref) async {
  ref.watch(dataRevisionProvider);
  return ref.watch(transactionHistoryDataSourceProvider).fetchRecentActivity();
});

/// Active items with low stock — hidden when empty.
final dashboardLowStockProvider = FutureProvider.autoDispose<List<Item>>((ref) async {
  final items = await ref.watch(itemListProvider.future);
  final lowStock = items
      .where((item) => item.isActive && item.openingStock <= dashboardLowStockThreshold)
      .toList()
    ..sort((a, b) => a.openingStock.compareTo(b.openingStock));
  return lowStock;
});
