import '../../../../core/errors/exception_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/utils/id_generator.dart';
import '../../domain/entities/party.dart';
import '../../domain/entities/party_history_builder.dart';
import '../../domain/entities/party_history_entry.dart';
import '../../domain/repositories/party_repository.dart';
import '../datasources/party_local_datasource.dart';
import '../models/party_model.dart';
import '../services/opening_balance_posting_service.dart';
import '../services/payment_posting_service.dart';

final class PartyRepositoryImpl implements PartyRepository {
  const PartyRepositoryImpl(
    this._localDataSource,
    this._openingBalanceService,
    this._paymentPostingService,
  );

  final PartyLocalDataSource _localDataSource;
  final OpeningBalancePostingService _openingBalanceService;
  final PaymentPostingService _paymentPostingService;

  @override
  Future<Result<List<Party>>> getParties({bool activeOnly = false}) async {
    try {
      final parties = await _localDataSource.fetchParties(activeOnly: activeOnly);
      return Success(parties);
    } catch (error, stackTrace) {
      return Error(ExceptionMapper.map(error, stackTrace));
    }
  }

  @override
  Future<Result<List<Party>>> searchParties(
    String query, {
    bool activeOnly = false,
  }) async {
    try {
      final parties = await _localDataSource.searchParties(
        query,
        activeOnly: activeOnly,
      );
      return Success(parties);
    } catch (error, stackTrace) {
      return Error(ExceptionMapper.map(error, stackTrace));
    }
  }

  @override
  Future<Result<Party?>> getParty(String id) async {
    try {
      final party = await _localDataSource.fetchParty(id);
      return Success(party);
    } catch (error, stackTrace) {
      return Error(ExceptionMapper.map(error, stackTrace));
    }
  }

  @override
  Future<Result<Party>> saveParty(SavePartyInput input) async {
    try {
      final businessId = await _localDataSource.currentBusinessId();
      if (businessId == null) {
        return const Error(
          ValidationFailure('Set up your business profile before adding parties'),
        );
      }

      final signedOpening = PartyModel.signedOpeningBalance(
        amount: input.openingAmount,
        direction: input.openingDirection,
      );

      final now = DateTime.now();
      final partyId = input.id ?? IdGenerator.newId();
      Party? existing;
      var hasOtherTransactions = false;

      if (input.id != null) {
        existing = await _localDataSource.fetchParty(input.id!);
        if (existing == null) {
          return const Error(ValidationFailure('Party not found'));
        }

        hasOtherTransactions = await _localDataSource.hasTransactions(partyId);
        if (hasOtherTransactions && signedOpening != existing.openingBalance) {
          return const Error(
            ValidationFailure(
              'Opening balance cannot be changed after other transactions exist',
            ),
          );
        }
      }

      final balance = _resolveBalance(
        existing: existing,
        signedOpening: signedOpening,
        hasOtherTransactions: hasOtherTransactions,
      );

      final draftParty = Party(
        id: partyId,
        businessId: businessId,
        name: input.name.trim(),
        type: input.type,
        phone: input.phone,
        address: input.address.trim(),
        gstin: input.gstin,
        openingBalance: signedOpening,
        balance: balance,
        creditLimit: input.creditLimit,
        isActive: input.isActive,
        openingTransactionId: existing?.openingTransactionId,
        createdAt: input.existingCreatedAt ?? existing?.createdAt ?? now,
        updatedAt: now,
      );

      await _localDataSource.upsertParty(draftParty);

      final openingTransactionId = await _openingBalanceService.post(
        businessId: businessId,
        party: draftParty,
        signedOpeningBalance: signedOpening,
        existingTransactionId: existing?.openingTransactionId,
      );

      final savedParty = draftParty.copyWith(
        openingTransactionId: openingTransactionId,
        clearOpeningTransactionId: openingTransactionId == null,
      );

      if (savedParty.openingTransactionId != draftParty.openingTransactionId) {
        await _localDataSource.upsertParty(savedParty);
      }
      return Success(savedParty);
    } catch (error, stackTrace) {
      return Error(ExceptionMapper.map(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> deleteParty(String id) async {
    try {
      final party = await _localDataSource.fetchParty(id);
      if (party == null) {
        return const Error(ValidationFailure('Party not found'));
      }

      if (await _localDataSource.hasTransactions(id)) {
        return const Error(
          ValidationFailure('Cannot delete a party with existing transactions'),
        );
      }

      if (party.openingTransactionId != null) {
        await _openingBalanceService.deleteOpeningTransaction(
          party.openingTransactionId!,
        );
      }

      await _localDataSource.removeParty(id);
      return const Success(null);
    } catch (error, stackTrace) {
      return Error(ExceptionMapper.map(error, stackTrace));
    }
  }

  @override
  Future<Result<bool>> hasTransactions(String partyId) async {
    try {
      final hasTransactions = await _localDataSource.hasTransactions(partyId);
      return Success(hasTransactions);
    } catch (error, stackTrace) {
      return Error(ExceptionMapper.map(error, stackTrace));
    }
  }

  @override
  Future<Result<List<PartyHistoryEntry>>> getPartyHistory(String partyId) async {
    try {
      final rows = await _localDataSource.fetchPartyHistory(partyId);
      return Success(PartyHistoryBuilder.build(rows));
    } catch (error, stackTrace) {
      return Error(ExceptionMapper.map(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> recordPaymentReceived(RecordPaymentInput input) async {
    try {
      final businessId = await _localDataSource.currentBusinessId();
      if (businessId == null) {
        return const Error(
          ValidationFailure('Pehle apni dukaan ka naam set karein'),
        );
      }
      await _paymentPostingService.recordReceived(
        businessId: businessId,
        partyId: input.partyId,
        amount: input.amount,
        date: input.date,
        note: input.note,
      );
      return const Success(null);
    } catch (error, stackTrace) {
      return Error(ExceptionMapper.map(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> recordPaymentPaid(RecordPaymentInput input) async {
    try {
      final businessId = await _localDataSource.currentBusinessId();
      if (businessId == null) {
        return const Error(
          ValidationFailure('Pehle apni dukaan ka naam set karein'),
        );
      }
      await _paymentPostingService.recordPaid(
        businessId: businessId,
        partyId: input.partyId,
        amount: input.amount,
        date: input.date,
        note: input.note,
      );
      return const Success(null);
    } catch (error, stackTrace) {
      return Error(ExceptionMapper.map(error, stackTrace));
    }
  }

  double _resolveBalance({
    required Party? existing,
    required double signedOpening,
    required bool hasOtherTransactions,
  }) {
    if (existing == null) return signedOpening;
    if (hasOtherTransactions) return existing.balance;
    return signedOpening;
  }
}
