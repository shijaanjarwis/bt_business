import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/di/data_revision.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../business/data/datasources/business_table.dart';
import '../../../ledger/domain/entities/party.dart';
import '../../../ledger/domain/usecases/get_parties.dart';
import '../../../ledger/domain/usecases/search_parties.dart';
import '../../../ledger/presentation/providers/party_providers.dart';
import '../../data/datasources/payment_register_local_datasource.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../data/services/expense_posting_service.dart';
import '../../domain/entities/payment_register_entry.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/usecases/record_expense.dart';
import '../models/payment_register_filter.dart';
import '../services/payment_register_actions.dart';

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

final paymentRegisterLocalDataSourceProvider =
    Provider<PaymentRegisterLocalDataSource>((ref) {
  final database = ref.watch(appDatabaseProvider).requireValue;
  return PaymentRegisterLocalDataSource(database);
});

final paymentRegisterActionsProvider = Provider<PaymentRegisterActions>((ref) {
  return PaymentRegisterActions(ref.watch(paymentPostingServiceProvider));
});

final paymentSearchQueryProvider = StateProvider<String>((ref) => '');

final paymentRegisterFilterProvider =
    StateProvider<PaymentRegisterFilter>((ref) => PaymentRegisterFilter.all);

final paymentListProvider = FutureProvider<List<PaymentRegisterEntry>>((ref) async {
  ref.watch(dataRevisionProvider);

  final query = ref.watch(paymentSearchQueryProvider);
  final filter = ref.watch(paymentRegisterFilterProvider);
  final datasource = ref.watch(paymentRegisterLocalDataSourceProvider);

  List<PaymentRegisterEntry> entries;
  if (query.trim().isNotEmpty) {
    entries = await datasource.searchPayments(query);
  } else {
    entries = await datasource.fetchPayments(filter: filter);
  }

  if (query.trim().isEmpty && filter != PaymentRegisterFilter.all) {
    entries = entries.where((entry) {
      return switch (filter) {
        PaymentRegisterFilter.received => entry.isReceived,
        PaymentRegisterFilter.paid => entry.isPaid,
        PaymentRegisterFilter.all => true,
      };
    }).toList();
  }

  return entries;
});

final paymentDetailProvider =
    FutureProvider.family<PaymentRegisterEntry?, String>((ref, id) async {
  ref.watch(dataRevisionProvider);
  return ref.watch(paymentRegisterLocalDataSourceProvider).fetchPayment(id);
});

final currentBusinessIdProvider = FutureProvider<String?>((ref) async {
  final db = ref.watch(appDatabaseProvider).requireValue;
  final rows = await db.query(BusinessTable.tableName, limit: 1);
  if (rows.isEmpty) return null;
  return rows.first[BusinessTable.id] as String;
});

final savePaymentProvider = Provider<
    Future<Result<String>> Function({
  required bool isReceived,
  required String partyId,
  required double amount,
  required DateTime dateTime,
  String? note,
  String? id,
})>((ref) {
  return ({
    required bool isReceived,
    required String partyId,
    required double amount,
    required DateTime dateTime,
    String? note,
    String? id,
  }) async {
    final businessId = await ref.read(currentBusinessIdProvider.future);
    if (businessId == null) {
      return const Error(ValidationFailure('Pehle apni dukaan ka naam set karein'));
    }
    return ref.read(paymentRegisterActionsProvider).save(
          businessId: businessId,
          isReceived: isReceived,
          partyId: partyId,
          amount: amount,
          dateTime: dateTime,
          note: note,
          id: id,
        );
  };
});

final deletePaymentProvider = Provider<Future<Result<void>> Function(String)>((ref) {
  return (id) => ref.read(paymentRegisterActionsProvider).delete(id);
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
