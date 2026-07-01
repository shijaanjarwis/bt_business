import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/di/data_revision.dart';
import '../../data/datasources/item_local_datasource.dart';
import '../../data/repositories/item_repository_impl.dart';
import '../../domain/entities/item.dart';
import '../../domain/repositories/item_repository.dart';
import '../../domain/usecases/delete_item.dart';
import '../../domain/usecases/save_item.dart';
import '../../domain/usecases/search_items.dart';

final itemLocalDataSourceProvider = Provider<ItemLocalDataSource>((ref) {
  final database = ref.watch(appDatabaseProvider).requireValue;
  return ItemLocalDataSource(database);
});

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepositoryImpl(ref.watch(itemLocalDataSourceProvider));
});

final saveItemUseCaseProvider = Provider<SaveItemUseCase>((ref) {
  return SaveItemUseCase(ref.watch(itemRepositoryProvider));
});

final searchItemsUseCaseProvider = Provider<SearchItemsUseCase>((ref) {
  return SearchItemsUseCase(ref.watch(itemRepositoryProvider));
});

final deleteItemUseCaseProvider = Provider<DeleteItemUseCase>((ref) {
  return DeleteItemUseCase(ref.watch(itemRepositoryProvider));
});

final itemSearchQueryProvider = StateProvider<String>((ref) => '');

final itemSearchProvider = FutureProvider.family<List<Item>, String>((ref, query) async {
  ref.watch(dataRevisionProvider);
  final result = await ref.watch(searchItemsUseCaseProvider)(query);
  if (result.isFailure) {
    throw result.failureOrNull!;
  }
  return result.valueOrNull ?? [];
});

final itemListProvider = FutureProvider<List<Item>>((ref) async {
  ref.watch(dataRevisionProvider);
  final result = await ref.watch(searchItemsUseCaseProvider)('');
  if (result.isFailure) {
    throw result.failureOrNull!;
  }
  return result.valueOrNull ?? [];
});

final itemDetailProvider = FutureProvider.family<Item?, String>((ref, id) async {
  ref.watch(dataRevisionProvider);
  final result = await ref.watch(itemRepositoryProvider).getItem(id);
  if (result.isFailure) {
    throw result.failureOrNull!;
  }
  return result.valueOrNull;
});
