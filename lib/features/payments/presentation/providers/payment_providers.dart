import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/di/data_revision.dart';
import '../../../ledger/domain/entities/party.dart';
import '../../../ledger/domain/usecases/get_parties.dart';
import '../../../ledger/domain/usecases/search_parties.dart';
import '../../../ledger/presentation/providers/party_providers.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../data/services/expense_posting_service.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/usecases/record_expense.dart';

final expensePostingServiceProvider = Provider<ExpensePostingService>((ref) {
  final database = ref.watch(appDatabaseProvider).requireValue;
  return ExpensePostingService(database);
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepositoryImpl(
    ref.watch(partyLocalDataSourceProvider),
    ref.watch(expensePostingServiceProvider),
  );
});

final recordExpenseUseCaseProvider = Provider<RecordExpenseUseCase>((ref) {
  return RecordExpenseUseCase(ref.watch(expenseRepositoryProvider));
});

final registerPartySearchProvider =
    FutureProvider.family<List<Party>, String>((ref, query) async {
  ref.watch(dataRevisionProvider);

  if (query.trim().isEmpty) {
    final result = await ref.watch(getPartiesUseCaseProvider)(
      const GetPartiesParams(),
    );
    if (result.isFailure) throw result.failureOrNull!;
    return result.valueOrNull ?? [];
  }

  final result = await ref.watch(searchPartiesUseCaseProvider)(
    SearchPartiesParams(query: query),
  );
  if (result.isFailure) throw result.failureOrNull!;
  return result.valueOrNull ?? [];
});
