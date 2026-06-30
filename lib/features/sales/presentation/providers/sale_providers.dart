import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/accounting/payment_modes.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/di/data_revision.dart';
import '../../../../core/errors/result.dart';
import '../../data/datasources/sale_local_datasource.dart';
import '../../data/repositories/sale_repository_impl.dart';
import '../../data/services/sale_posting_service.dart';
import '../../data/models/sale_item_model.dart';
import '../../domain/entities/sale_invoice.dart';
import '../../domain/repositories/sale_repository.dart';
import '../../domain/usecases/delete_sale.dart';
import '../../domain/usecases/get_sale.dart';
import '../../domain/usecases/get_sales.dart';
import '../../domain/usecases/save_sale.dart';
import '../../domain/usecases/search_sale_items.dart';
import '../../domain/usecases/search_sales.dart';

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

final searchSaleItemsUseCaseProvider = Provider<SearchSaleItemsUseCase>((ref) {
  return SearchSaleItemsUseCase(ref.watch(saleLocalDataSourceProvider));
});

final saleSearchQueryProvider = StateProvider<String>((ref) => '');

final salePaymentFilterProvider = StateProvider<PaymentMode?>((ref) => null);

final saleListProvider = FutureProvider<List<SaleInvoice>>((ref) async {
  ref.watch(dataRevisionProvider);

  final query = ref.watch(saleSearchQueryProvider);
  final paymentFilter = ref.watch(salePaymentFilterProvider);

  final Result<List<SaleInvoice>> result;
  if (query.trim().isNotEmpty) {
    result = await ref.watch(searchSalesUseCaseProvider)(query);
  } else {
    result = await ref.watch(getSalesUseCaseProvider)(
      GetSalesParams(paymentMode: paymentFilter),
    );
  }

  if (result.isFailure) {
    throw result.failureOrNull!;
  }

  var sales = result.valueOrNull ?? [];
  if (query.trim().isEmpty && paymentFilter != null) {
    sales = sales.where((sale) => sale.paymentMode == paymentFilter).toList();
  }
  return sales;
});

final saleDetailProvider =
    FutureProvider.family<SaleInvoice?, String>((ref, id) async {
  ref.watch(dataRevisionProvider);
  final result = await ref.watch(getSaleUseCaseProvider)(id);
  if (result.isFailure) {
    throw result.failureOrNull!;
  }
  return result.valueOrNull;
});

final saleItemsSearchProvider =
    FutureProvider.family<List<SaleItem>, String>((ref, query) async {
  final result = await ref.watch(searchSaleItemsUseCaseProvider)(query);
  if (result.isFailure) {
    throw result.failureOrNull!;
  }
  return result.valueOrNull ?? [];
});
