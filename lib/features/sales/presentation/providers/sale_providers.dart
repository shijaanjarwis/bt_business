import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/di/data_revision.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/utils/register_date_period.dart';
import '../../../../data/local/database/seeders/cash_customer_seeder.dart';
import '../../../../shared/utils/register_entry_sort.dart';
import '../../data/datasources/sale_local_datasource.dart';
import '../../data/repositories/sale_repository_impl.dart';
import '../../data/services/sale_posting_service.dart';
import '../../../../core/utils/register_list_filters.dart';
import '../../domain/entities/sale_entry.dart';
import '../../domain/repositories/sale_repository.dart';
import '../../domain/usecases/delete_sale.dart';
import '../../domain/usecases/get_sale.dart';
import '../../domain/usecases/get_sales.dart';
import '../../domain/usecases/save_sale.dart';
import '../../domain/usecases/search_sales.dart';
import '../../../business/data/datasources/business_table.dart';
import '../../../ledger/domain/entities/party.dart';
import '../../../ledger/domain/usecases/get_parties.dart';
import '../../../ledger/domain/usecases/search_parties.dart';
import '../../../ledger/presentation/providers/party_providers.dart';
import '../models/sale_register_filter.dart';
import '../utils/sale_ui_helpers.dart';

final saleLocalDataSourceProvider = Provider<SaleLocalDataSource>((ref) {
  final database = ref.watch(appDatabaseProvider).requireValue;
  return SaleLocalDataSource(database);
});

final salePostingServiceProvider = Provider<SalePostingService>((ref) {
  final database = ref.watch(appDatabaseProvider).requireValue;
  return SalePostingService(database);
});

final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  return SaleRepositoryImpl(
    ref.watch(saleLocalDataSourceProvider),
    ref.watch(salePostingServiceProvider),
  );
});

final getSalesUseCaseProvider = Provider<GetSalesUseCase>((ref) {
  return GetSalesUseCase(ref.watch(saleRepositoryProvider));
});

final searchSalesUseCaseProvider = Provider<SearchSalesUseCase>((ref) {
  return SearchSalesUseCase(ref.watch(saleRepositoryProvider));
});

final getSaleUseCaseProvider = Provider<GetSaleUseCase>((ref) {
  return GetSaleUseCase(ref.watch(saleRepositoryProvider));
});

final saveSaleUseCaseProvider = Provider<SaveSaleUseCase>((ref) {
  return SaveSaleUseCase(ref.watch(saleRepositoryProvider));
});

final deleteSaleUseCaseProvider = Provider<DeleteSaleUseCase>((ref) {
  return DeleteSaleUseCase(ref.watch(saleRepositoryProvider));
});

final saleSearchQueryProvider = StateProvider<String>((ref) => '');

final saleRegisterFilterProvider =
    StateProvider<SaleRegisterFilter>((ref) => SaleRegisterFilter.all);

final saleRegisterDatePeriodProvider = StateProvider<RegisterDatePeriod>(
  (ref) => RegisterDatePeriod.today,
);

final saleRegisterCustomStartProvider = StateProvider<DateTime?>((ref) => null);
final saleRegisterCustomEndProvider = StateProvider<DateTime?>((ref) => null);

/// Built-in walk-in party id for cash sales when no party is chosen.
final cashCustomerPartyIdProvider = FutureProvider.autoDispose<String>((ref) async {
  ref.watch(dataRevisionProvider);
  final db = ref.watch(appDatabaseProvider).requireValue;
  final rows = await db.query(BusinessTable.tableName, limit: 1);
  if (rows.isEmpty) {
    throw StateError('Business profile missing');
  }
  final businessId = rows.first[BusinessTable.id]! as String;
  final existing = await CashCustomerSeeder.idForBusiness(db, businessId);
  if (existing != null) return existing;
  return CashCustomerSeeder.seedForBusiness(db, businessId);
});

RegisterListFilters _saleListFilters({
  required RegisterDatePeriod datePeriod,
  DateTime? customStart,
  DateTime? customEnd,
  required SaleRegisterFilter registerFilter,
}) {
  final range = RegisterDateRange.resolve(
    period: datePeriod,
    customStart: customStart,
    customEnd: customEnd,
  );

  double? minDueAmount;
  double? minPaidAmount;
  switch (registerFilter) {
    case SaleRegisterFilter.all:
      break;
    case SaleRegisterFilter.hasBalance:
      minDueAmount = 0.001;
    case SaleRegisterFilter.todayCashReceived:
      minPaidAmount = 0.001;
  }

  return RegisterListFilters(
    fromDate: range.start,
    toDate: range.end,
    minDueAmount: minDueAmount,
    minPaidAmount: minPaidAmount,
  );
}

final saleListProvider = FutureProvider.autoDispose<List<SaleEntry>>((ref) async {
  ref.watch(dataRevisionProvider);

  final query = ref.watch(saleSearchQueryProvider);
  final registerFilter = ref.watch(saleRegisterFilterProvider);
  final datePeriod = ref.watch(saleRegisterDatePeriodProvider);
  final customStart = ref.watch(saleRegisterCustomStartProvider);
  final customEnd = ref.watch(saleRegisterCustomEndProvider);
  final filters = _saleListFilters(
    datePeriod: datePeriod,
    customStart: customStart,
    customEnd: customEnd,
    registerFilter: registerFilter,
  );

  final Result<List<SaleEntry>> result;
  if (query.trim().isNotEmpty) {
    result = await ref.watch(searchSalesUseCaseProvider)(
      SearchRegisterParams(query: query, filters: filters),
    );
  } else {
    result = await ref.watch(getSalesUseCaseProvider)(
      GetSalesParams(
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

  var sales = result.valueOrNull ?? [];
  if (registerFilter == SaleRegisterFilter.todayCashReceived) {
    sales = sales
        .where((sale) => SaleUiHelpers.matchesRegisterFilter(sale, registerFilter))
        .toList();
  }

  sales.sort(
    (a, b) => RegisterEntrySort.compareDates(a.date, a.createdAt, b.date, b.createdAt),
  );

  return sales;
});

final saleDetailProvider =
    FutureProvider.autoDispose.family<SaleEntry?, String>((ref, id) async {
  ref.watch(dataRevisionProvider);
  final result = await ref.watch(getSaleUseCaseProvider)(id);
  if (result.isFailure) {
    throw result.failureOrNull!;
  }
  return result.valueOrNull;
});

/// All parties for sale/purchase entry pickers.
final salePartySearchProvider =
    FutureProvider.autoDispose.family<List<Party>, String>((ref, query) async {
  ref.watch(dataRevisionProvider);

  final Result<List<Party>> result;
  if (query.trim().isEmpty) {
    result = await ref.watch(getPartiesUseCaseProvider)(
      const GetPartiesParams(activeOnly: true),
    );
  } else {
    result = await ref.watch(searchPartiesUseCaseProvider)(
      SearchPartiesParams(query: query, activeOnly: true),
    );
  }

  if (result.isFailure) {
    throw result.failureOrNull!;
  }

  return result.valueOrNull ?? [];
});
