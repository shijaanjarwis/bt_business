import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/di/data_revision.dart';
import '../../../../core/errors/result.dart';
import '../../data/datasources/party_local_datasource.dart';
import '../../data/repositories/party_repository_impl.dart';
import '../../data/services/opening_balance_posting_service.dart';
import '../../domain/entities/party.dart';
import '../../domain/repositories/party_repository.dart';
import '../../domain/usecases/delete_party.dart';
import '../../domain/usecases/get_parties.dart';
import '../../domain/usecases/get_party.dart';
import '../../domain/usecases/save_party.dart';
import '../../domain/usecases/search_parties.dart';

final partyLocalDataSourceProvider = Provider<PartyLocalDataSource>((ref) {
  final database = ref.watch(appDatabaseProvider).requireValue;
  return PartyLocalDataSource(database);
});

final openingBalancePostingServiceProvider =
    Provider<OpeningBalancePostingService>((ref) {
  final database = ref.watch(appDatabaseProvider).requireValue;
  return OpeningBalancePostingService(database);
});

final partyRepositoryProvider = Provider<PartyRepository>((ref) {
  return PartyRepositoryImpl(
    ref.watch(partyLocalDataSourceProvider),
    ref.watch(openingBalancePostingServiceProvider),
  );
});

final getPartiesUseCaseProvider = Provider<GetPartiesUseCase>((ref) {
  return GetPartiesUseCase(ref.watch(partyRepositoryProvider));
});

final searchPartiesUseCaseProvider = Provider<SearchPartiesUseCase>((ref) {
  return SearchPartiesUseCase(ref.watch(partyRepositoryProvider));
});

final getPartyUseCaseProvider = Provider<GetPartyUseCase>((ref) {
  return GetPartyUseCase(ref.watch(partyRepositoryProvider));
});

final savePartyUseCaseProvider = Provider<SavePartyUseCase>((ref) {
  return SavePartyUseCase(ref.watch(partyRepositoryProvider));
});

final deletePartyUseCaseProvider = Provider<DeletePartyUseCase>((ref) {
  return DeletePartyUseCase(ref.watch(partyRepositoryProvider));
});

/// Search text for the ledger list.
final partySearchQueryProvider = StateProvider<String>((ref) => '');

/// `null` = all, `true` = active only, `false` = inactive only.
final partyStatusFilterProvider = StateProvider<bool?>((ref) => null);

final partyListProvider = FutureProvider<List<Party>>((ref) async {
  ref.watch(dataRevisionProvider);

  final query = ref.watch(partySearchQueryProvider);
  final statusFilter = ref.watch(partyStatusFilterProvider);
  final activeOnly = statusFilter == true;

  final Result<List<Party>> result;
  if (query.trim().isNotEmpty) {
    result = await ref.watch(searchPartiesUseCaseProvider)(
      SearchPartiesParams(query: query, activeOnly: activeOnly),
    );
  } else {
    result = await ref.watch(getPartiesUseCaseProvider)(
      GetPartiesParams(activeOnly: activeOnly),
    );
  }

  if (result.isFailure) {
    throw result.failureOrNull!;
  }

  var parties = result.valueOrNull ?? [];
  if (statusFilter == false) {
    parties = parties.where((party) => !party.isActive).toList();
  }
  return parties;
});

final partyDetailProvider =
    FutureProvider.family<Party?, String>((ref, id) async {
  ref.watch(dataRevisionProvider);
  final result = await ref.watch(getPartyUseCaseProvider)(id);
  if (result.isFailure) {
    throw result.failureOrNull!;
  }
  return result.valueOrNull;
});
