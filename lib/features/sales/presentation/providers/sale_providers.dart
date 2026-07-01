import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/di/data_revision.dart';
import '../../../../core/errors/result.dart';
import '../../../../data/local/database/seeders/cash_customer_seeder.dart';
import '../../../../features/business/data/datasources/business_table.dart';
import '../../../ledger/domain/entities/party.dart';
import '../../../ledger/domain/usecases/get_parties.dart';
import '../../../ledger/domain/usecases/search_parties.dart';
import '../../../ledger/presentation/providers/party_providers.dart';
import '../../data/datasources/sale_local_datasource.dart';
import '../../data/repositories/sale_repository_impl.dart';
import '../../data/services/sale_posting_service.dart';
import '../../domain/entities/sale_entry.dart';
import '../../domain/repositories/sale_repository.dart';
import '../../domain/usecases/delete_sale.dart';
import '../../domain/usecases/get_sale.dart';
import '../../domain/usecases/get_sales.dart';
import '../../domain/usecases/save_sale.dart';
import '../../domain/usecases/search_sales.dart';
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

/// Built-in walk-in party id for cash sales when no party is chosen.
final cashCustomerPartyIdProvider = FutureProvider<String>((ref) async {
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

final saleListProvider = FutureProvider<List<SaleEntry>>((ref) async {
  ref.watch(dataRevisionProvider);

  final query = ref.watch(saleSearchQueryProvider);
  final registerFilter = ref.watch(saleRegisterFilterProvider);

  final Result<List<SaleEntry>> result;
  if (query.trim().isNotEmpty) {
    result = await ref.watch(searchSalesUseCaseProvider)(query);
  } else {
    result = await ref.watch(getSalesUseCaseProvider)(const GetSalesParams());
  }

  if (result.isFailure) {
    throw result.failureOrNull!;
  }

  var sales = result.valueOrNull ?? [];
  if (registerFilter != SaleRegisterFilter.all) {
    sales = sales
        .where((sale) => SaleUiHelpers.matchesRegisterFilter(sale, registerFilter))
        .toList();
  }

  return sales;
});

final saleDetailProvider =
    FutureProvider.family<SaleEntry?, String>((ref, id) async {
  ref.watch(dataRevisionProvider);
  final result = await ref.watch(getSaleUseCaseProvider)(id);
  if (result.isFailure) {
    throw result.failureOrNull!;
  }
  return result.valueOrNull;
});

/// All parties for sale/purchase entry pickers.
final salePartySearchProvider =
    FutureProvider.family<List<Party>, String>((ref, query) async {
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
