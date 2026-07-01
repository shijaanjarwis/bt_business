import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/di/data_revision.dart';
import '../../../../core/errors/result.dart';
import '../../data/datasources/party_local_datasource.dart';
import '../../data/repositories/party_repository_impl.dart';
import '../../data/services/opening_balance_posting_service.dart';
import '../../data/services/payment_posting_service.dart';
import '../../domain/entities/party.dart';
import '../../domain/entities/party_history_entry.dart';
import '../../domain/repositories/party_repository.dart';
import '../../domain/usecases/delete_party.dart';
import '../../domain/usecases/get_parties.dart';
import '../../domain/usecases/get_party.dart';
import '../../domain/usecases/party_hisaab_usecases.dart';
import '../../domain/usecases/save_party.dart';
import '../../domain/usecases/search_parties.dart';
import '../utils/party_ledger_ui_helpers.dart';

final partyLocalDataSourceProvider = Provider<PartyLocalDataSource>((ref) {
  final database = ref.watch(appDatabaseProvider).requireValue;
  return PartyLocalDataSource(database);
});

final openingBalancePostingServiceProvider =
    Provider<OpeningBalancePostingService>((ref) {
  final database = ref.watch(appDatabaseProvider).requireValue;
  return OpeningBalancePostingService(database);
});

final paymentPostingServiceProvider = Provider<PaymentPostingService>((ref) {
  final database = ref.watch(appDatabaseProvider).requireValue;
  return PaymentPostingService(database);
});

final partyRepositoryProvider = Provider<PartyRepository>((ref) {
  return PartyRepositoryImpl(
    ref.watch(partyLocalDataSourceProvider),
    ref.watch(openingBalancePostingServiceProvider),
    ref.watch(paymentPostingServiceProvider),
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

final getPartyHistoryUseCaseProvider = Provider<GetPartyHistoryUseCase>((ref) {
  return GetPartyHistoryUseCase(ref.watch(partyRepositoryProvider));
});

final recordPaymentReceivedUseCaseProvider =
    Provider<RecordPaymentReceivedUseCase>((ref) {
  return RecordPaymentReceivedUseCase(ref.watch(partyRepositoryProvider));
});

final recordPaymentPaidUseCaseProvider = Provider<RecordPaymentPaidUseCase>((ref) {
  return RecordPaymentPaidUseCase(ref.watch(partyRepositoryProvider));
});

/// Which parties to show on the Hisaab list.
enum PartyBalanceFilter { all, lena, dena, saaf }

final partyBalanceFilterProvider =
    StateProvider<PartyBalanceFilter>((ref) => PartyBalanceFilter.all);

final partySearchQueryProvider = StateProvider<String>((ref) => '');

final partyListProvider = FutureProvider<List<Party>>((ref) async {
  ref.watch(dataRevisionProvider);

  final query = ref.watch(partySearchQueryProvider);
  final filter = ref.watch(partyBalanceFilterProvider);

  final Result<List<Party>> result;
  if (query.trim().isNotEmpty) {
    result = await ref.watch(searchPartiesUseCaseProvider)(
      SearchPartiesParams(query: query),
    );
  } else {
    result = await ref.watch(getPartiesUseCaseProvider)(
      const GetPartiesParams(),
    );
  }

  if (result.isFailure) {
    throw result.failureOrNull!;
  }

  var parties = result.valueOrNull ?? [];
  if (filter != PartyBalanceFilter.all) {
    parties = parties
        .where((party) => PartyLedgerUiHelpers.matchesFilter(party, filter))
        .toList();
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

final partyHistoryProvider =
    FutureProvider.family<List<PartyHistoryEntry>, String>((ref, partyId) async {
  ref.watch(dataRevisionProvider);
  final result = await ref.watch(getPartyHistoryUseCaseProvider)(partyId);
  if (result.isFailure) {
    throw result.failureOrNull!;
  }
  return result.valueOrNull ?? [];
});
