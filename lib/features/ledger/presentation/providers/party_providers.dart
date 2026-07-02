import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/di/data_revision.dart';
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

({bool receivableOnly, bool payableOnly, bool clearOnly}) _balanceFlags(
  PartyBalanceFilter filter,
) {
  return switch (filter) {
    PartyBalanceFilter.all => (
        receivableOnly: false,
        payableOnly: false,
        clearOnly: false,
      ),
    PartyBalanceFilter.lena => (
        receivableOnly: true,
        payableOnly: false,
        clearOnly: false,
      ),
    PartyBalanceFilter.dena => (
        receivableOnly: false,
        payableOnly: true,
        clearOnly: false,
      ),
    PartyBalanceFilter.saaf => (
        receivableOnly: false,
        payableOnly: false,
        clearOnly: true,
      ),
  };
}

final partyListProvider = FutureProvider.autoDispose<List<Party>>((ref) async {
  ref.watch(dataRevisionProvider);

  final query = ref.watch(partySearchQueryProvider);
  final filter = ref.watch(partyBalanceFilterProvider);
  final flags = _balanceFlags(filter);
  final datasource = ref.watch(partyLocalDataSourceProvider);

  if (query.trim().isNotEmpty) {
    return datasource.searchParties(
      query,
      receivableOnly: flags.receivableOnly,
      payableOnly: flags.payableOnly,
      clearOnly: flags.clearOnly,
    );
  }

  return datasource.fetchParties(
    receivableOnly: flags.receivableOnly,
    payableOnly: flags.payableOnly,
    clearOnly: flags.clearOnly,
  );
});

final partyDetailProvider =
    FutureProvider.autoDispose.family<Party?, String>((ref, id) async {
  ref.watch(dataRevisionProvider);
  final result = await ref.watch(getPartyUseCaseProvider)(id);
  if (result.isFailure) {
    throw result.failureOrNull!;
  }
  return result.valueOrNull;
});

final partyHistoryProvider =
    FutureProvider.autoDispose.family<List<PartyHistoryEntry>, String>((ref, partyId) async {
  ref.watch(dataRevisionProvider);
  final result = await ref.watch(getPartyHistoryUseCaseProvider)(partyId);
  if (result.isFailure) {
    throw result.failureOrNull!;
  }
  return result.valueOrNull ?? [];
});
