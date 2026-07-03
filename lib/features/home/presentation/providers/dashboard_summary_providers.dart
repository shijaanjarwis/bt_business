import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/di/data_revision.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/utils/register_date_period.dart';
import '../../../../core/utils/register_list_filters.dart';
import '../../../../shared/utils/register_entry_sort.dart';
import '../../../purchase/domain/entities/purchase_invoice.dart';
import '../../../purchase/domain/usecases/get_purchases.dart';
import '../../../purchase/presentation/providers/purchase_providers.dart';
import '../../../sales/domain/entities/sale_entry.dart';
import '../../../sales/domain/usecases/get_sales.dart';
import '../../../sales/presentation/providers/sale_providers.dart';
import '../../data/datasources/dashboard_summary_local_datasource.dart';
import '../../domain/entities/dashboard_summary_entry.dart';
import '../models/dashboard_summary_kind.dart';

final dashboardSummaryLocalDataSourceProvider =
    Provider<DashboardSummaryLocalDataSource>((ref) {
  final database = ref.watch(appDatabaseProvider).requireValue;
  return DashboardSummaryLocalDataSource(database);
});

final dashboardSummarySearchProvider =
    StateProvider.family<String, DashboardSummaryKind>((ref, kind) => '');

final dashboardSummaryDatePeriodProvider =
    StateProvider.family<RegisterDatePeriod, DashboardSummaryKind>((ref, kind) {
  return kind == DashboardSummaryKind.cashInHand
      ? RegisterDatePeriod.thisMonth
      : RegisterDatePeriod.today;
});

final dashboardSummaryCustomStartProvider =
    StateProvider.family<DateTime?, DashboardSummaryKind>((ref, kind) => null);

final dashboardSummaryCustomEndProvider =
    StateProvider.family<DateTime?, DashboardSummaryKind>((ref, kind) => null);

final dashboardSummarySalesProvider =
    FutureProvider.autoDispose.family<List<SaleEntry>, DashboardSummaryKind>(
        (ref, kind) async {
  if (!kind.usesSaleEntries) return [];

  ref.watch(dataRevisionProvider);
  final query = ref.watch(dashboardSummarySearchProvider(kind));
  final datePeriod = ref.watch(dashboardSummaryDatePeriodProvider(kind));
  final customStart = ref.watch(dashboardSummaryCustomStartProvider(kind));
  final customEnd = ref.watch(dashboardSummaryCustomEndProvider(kind));
  final range = RegisterDateRange.resolve(
    period: datePeriod,
    customStart: customStart,
    customEnd: customEnd,
  );

  final minDueAmount =
      kind == DashboardSummaryKind.todayCredit ? 0.001 : null;

  final Result<List<SaleEntry>> result;
  if (query.trim().isNotEmpty) {
    result = await ref.watch(searchSalesUseCaseProvider)(
      SearchRegisterParams(
        query: query,
        filters: RegisterListFilters(
          fromDate: range.start,
          toDate: range.end,
          minDueAmount: minDueAmount,
        ),
      ),
    );
  } else {
    result = await ref.watch(getSalesUseCaseProvider)(
      GetSalesParams(
        fromDate: range.start,
        toDate: range.end,
        minDueAmount: minDueAmount,
      ),
    );
  }

  if (result.isFailure) throw result.failureOrNull!;

  final sales = List<SaleEntry>.from(result.valueOrNull ?? [])
    ..sort(
      (a, b) => RegisterEntrySort.compareDates(a.date, a.createdAt, b.date, b.createdAt),
    );
  return sales;
});

final dashboardSummaryPurchasesProvider =
    FutureProvider.autoDispose.family<List<PurchaseInvoice>, DashboardSummaryKind>(
        (ref, kind) async {
  if (!kind.usesPurchaseEntries) return [];

  ref.watch(dataRevisionProvider);
  final query = ref.watch(dashboardSummarySearchProvider(kind));
  final datePeriod = ref.watch(dashboardSummaryDatePeriodProvider(kind));
  final customStart = ref.watch(dashboardSummaryCustomStartProvider(kind));
  final customEnd = ref.watch(dashboardSummaryCustomEndProvider(kind));
  final range = RegisterDateRange.resolve(
    period: datePeriod,
    customStart: customStart,
    customEnd: customEnd,
  );

  final Result<List<PurchaseInvoice>> result;
  if (query.trim().isNotEmpty) {
    result = await ref.watch(searchPurchasesUseCaseProvider)(
      SearchRegisterParams(
        query: query,
        filters: RegisterListFilters(
          fromDate: range.start,
          toDate: range.end,
        ),
      ),
    );
  } else {
    result = await ref.watch(getPurchasesUseCaseProvider)(
      GetPurchasesParams(
        fromDate: range.start,
        toDate: range.end,
      ),
    );
  }

  if (result.isFailure) throw result.failureOrNull!;

  final purchases = List<PurchaseInvoice>.from(result.valueOrNull ?? [])
    ..sort(
      (a, b) => RegisterEntrySort.compareDates(a.date, a.createdAt, b.date, b.createdAt),
    );
  return purchases;
});

final dashboardSummaryEntriesProvider =
    FutureProvider.autoDispose.family<List<DashboardSummaryEntry>, DashboardSummaryKind>(
        (ref, kind) async {
  if (kind.usesSaleEntries || kind.usesPurchaseEntries) return [];

  ref.watch(dataRevisionProvider);
  final query = ref.watch(dashboardSummarySearchProvider(kind));
  final datePeriod = ref.watch(dashboardSummaryDatePeriodProvider(kind));
  final customStart = ref.watch(dashboardSummaryCustomStartProvider(kind));
  final customEnd = ref.watch(dashboardSummaryCustomEndProvider(kind));
  final range = RegisterDateRange.resolve(
    period: datePeriod,
    customStart: customStart,
    customEnd: customEnd,
  );
  final datasource = ref.watch(dashboardSummaryLocalDataSourceProvider);
  final trimmed = query.trim();

  return switch (kind) {
    DashboardSummaryKind.todayCashReceived => datasource.fetchCashReceived(
        fromDate: range.start,
        toDate: range.end,
        searchQuery: trimmed.isEmpty ? null : trimmed,
      ),
    DashboardSummaryKind.cashInHand => datasource.fetchCashLedger(
        fromDate: range.start,
        toDate: range.end,
        searchQuery: trimmed.isEmpty ? null : trimmed,
      ),
    _ => const [],
  };
});
