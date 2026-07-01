import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/di/data_revision.dart';
import '../../../../core/errors/result.dart';
import '../../../../features/sales/data/models/sale_item_model.dart';
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

final purchaseListProvider = FutureProvider<List<PurchaseInvoice>>((ref) async {
  ref.watch(dataRevisionProvider);

  final query = ref.watch(purchaseSearchQueryProvider);
  final registerFilter = ref.watch(purchaseRegisterFilterProvider);

  final Result<List<PurchaseInvoice>> result;
  if (query.trim().isNotEmpty) {
    result = await ref.watch(searchPurchasesUseCaseProvider)(query);
  } else {
    result = await ref.watch(getPurchasesUseCaseProvider)(const GetPurchasesParams());
  }

  if (result.isFailure) {
    throw result.failureOrNull!;
  }

  var purchases = result.valueOrNull ?? [];
  if (registerFilter != PurchaseRegisterFilter.all) {
    purchases = purchases
        .where(
          (invoice) =>
              PurchaseUiHelpers.matchesRegisterFilter(invoice, registerFilter),
        )
        .toList();
  }

  return purchases;
});

final purchaseDetailProvider =
    FutureProvider.family<PurchaseInvoice?, String>((ref, id) async {
  ref.watch(dataRevisionProvider);
  final result = await ref.watch(getPurchaseUseCaseProvider)(id);
  if (result.isFailure) {
    throw result.failureOrNull!;
  }
  return result.valueOrNull;
});

final purchaseItemsSearchProvider =
    FutureProvider.family<List<SaleItem>, String>((ref, query) async {
  final result = await ref.watch(searchPurchaseItemsUseCaseProvider)(query);
  if (result.isFailure) {
    throw result.failureOrNull!;
  }
  return result.valueOrNull ?? [];
});
