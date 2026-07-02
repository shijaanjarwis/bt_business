import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/di/data_revision.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/utils/register_date_period.dart';
import '../../../../core/utils/register_list_filters.dart';
import '../../../../features/sales/data/models/sale_item_model.dart';
import '../../../../shared/utils/register_entry_sort.dart';
import '../../data/datasources/purchase_local_datasource.dart';
import '../../data/repositories/purchase_repository_impl.dart';
import '../../data/services/purchase_posting_service.dart';
import '../../domain/entities/purchase_invoice.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../../domain/usecases/delete_purchase.dart';
import '../../domain/usecases/get_purchase.dart';
import '../../domain/usecases/get_purchases.dart';
import '../../domain/usecases/save_purchase.dart';
import '../../domain/usecases/search_purchase_items.dart';
import '../../domain/usecases/search_purchases.dart';
import '../models/purchase_register_filter.dart';
import '../utils/purchase_ui_helpers.dart';

final purchaseLocalDataSourceProvider = Provider<PurchaseLocalDataSource>((ref) {
  final database = ref.watch(appDatabaseProvider).requireValue;
  return PurchaseLocalDataSource(database);
});

final purchasePostingServiceProvider = Provider<PurchasePostingService>((ref) {
  final database = ref.watch(appDatabaseProvider).requireValue;
  return PurchasePostingService(database);
});

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  return PurchaseRepositoryImpl(
    ref.watch(purchaseLocalDataSourceProvider),
    ref.watch(purchasePostingServiceProvider),
  );
});

final getPurchasesUseCaseProvider = Provider<GetPurchasesUseCase>((ref) {
  return GetPurchasesUseCase(ref.watch(purchaseRepositoryProvider));
});

final searchPurchasesUseCaseProvider = Provider<SearchPurchasesUseCase>((ref) {
  return SearchPurchasesUseCase(ref.watch(purchaseRepositoryProvider));
});

final getPurchaseUseCaseProvider = Provider<GetPurchaseUseCase>((ref) {
  return GetPurchaseUseCase(ref.watch(purchaseRepositoryProvider));
});

final savePurchaseUseCaseProvider = Provider<SavePurchaseUseCase>((ref) {
  return SavePurchaseUseCase(ref.watch(purchaseRepositoryProvider));
});

final deletePurchaseUseCaseProvider = Provider<DeletePurchaseUseCase>((ref) {
  return DeletePurchaseUseCase(ref.watch(purchaseRepositoryProvider));
});

final searchPurchaseItemsUseCaseProvider = Provider<SearchPurchaseItemsUseCase>((ref) {
  return SearchPurchaseItemsUseCase(ref.watch(purchaseLocalDataSourceProvider));
});

final purchaseSearchQueryProvider = StateProvider<String>((ref) => '');

final purchaseRegisterFilterProvider =
    StateProvider<PurchaseRegisterFilter>((ref) => PurchaseRegisterFilter.all);

final purchaseRegisterDatePeriodProvider = StateProvider<RegisterDatePeriod>(
  (ref) => RegisterDatePeriod.today,
);

final purchaseRegisterCustomStartProvider = StateProvider<DateTime?>((ref) => null);
final purchaseRegisterCustomEndProvider = StateProvider<DateTime?>((ref) => null);

RegisterListFilters _purchaseListFilters({
  required RegisterDatePeriod datePeriod,
  DateTime? customStart,
  DateTime? customEnd,
  required PurchaseRegisterFilter registerFilter,
}) {
  final range = RegisterDateRange.resolve(
    period: datePeriod,
    customStart: customStart,
    customEnd: customEnd,
  );

  double? minDueAmount;
  double? minPaidAmount;
  switch (registerFilter) {
    case PurchaseRegisterFilter.all:
      break;
    case PurchaseRegisterFilter.hasBalance:
      minDueAmount = 0.001;
    case PurchaseRegisterFilter.todayPaid:
      minPaidAmount = 0.001;
  }

  return RegisterListFilters(
    fromDate: range.start,
    toDate: range.end,
    minDueAmount: minDueAmount,
    minPaidAmount: minPaidAmount,
  );
}

final purchaseListProvider =
    FutureProvider.autoDispose<List<PurchaseInvoice>>((ref) async {
  ref.watch(dataRevisionProvider);

  final query = ref.watch(purchaseSearchQueryProvider);
  final registerFilter = ref.watch(purchaseRegisterFilterProvider);
  final datePeriod = ref.watch(purchaseRegisterDatePeriodProvider);
  final customStart = ref.watch(purchaseRegisterCustomStartProvider);
  final customEnd = ref.watch(purchaseRegisterCustomEndProvider);
  final filters = _purchaseListFilters(
    datePeriod: datePeriod,
    customStart: customStart,
    customEnd: customEnd,
    registerFilter: registerFilter,
  );

  final Result<List<PurchaseInvoice>> result;
  if (query.trim().isNotEmpty) {
    result = await ref.watch(searchPurchasesUseCaseProvider)(
      SearchRegisterParams(query: query, filters: filters),
    );
  } else {
    result = await ref.watch(getPurchasesUseCaseProvider)(
      GetPurchasesParams(
        fromDate: filters.fromDate,
        toDate: filters.toDate,
        paymentMode: filters.paymentMode,
        minDueAmount: filters.minDueAmount,
        minPaidAmount: filters.minPaidAmount,
      ),
    );
  }

  if (result.isFailure) {
    throw result.failureOrNull!;
  }

  var purchases = result.valueOrNull ?? [];
  if (registerFilter == PurchaseRegisterFilter.todayPaid) {
    purchases = purchases
        .where(
          (invoice) =>
              PurchaseUiHelpers.matchesRegisterFilter(invoice, registerFilter),
        )
        .toList();
  }

  purchases.sort(
    (a, b) => RegisterEntrySort.compareDates(a.date, a.createdAt, b.date, b.createdAt),
  );

  return purchases;
});

final purchaseDetailProvider =
    FutureProvider.autoDispose.family<PurchaseInvoice?, String>((ref, id) async {
  ref.watch(dataRevisionProvider);
  final result = await ref.watch(getPurchaseUseCaseProvider)(id);
  if (result.isFailure) {
    throw result.failureOrNull!;
  }
  return result.valueOrNull;
});

final purchaseItemsSearchProvider =
    FutureProvider.autoDispose.family<List<SaleItem>, String>((ref, query) async {
  final result = await ref.watch(searchPurchaseItemsUseCaseProvider)(query);
  if (result.isFailure) {
    throw result.failureOrNull!;
  }
  return result.valueOrNull ?? [];
});
