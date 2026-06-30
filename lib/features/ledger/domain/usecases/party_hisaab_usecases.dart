import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/party_history_entry.dart';
import '../repositories/party_repository.dart';

final class GetPartyHistoryUseCase implements UseCase<List<PartyHistoryEntry>, String> {
  const GetPartyHistoryUseCase(this._repository);

  final PartyRepository _repository;

  @override
  Future<Result<List<PartyHistoryEntry>>> call(String partyId) {
    return _repository.getPartyHistory(partyId);
  }
}

final class RecordPaymentReceivedUseCase implements UseCase<void, RecordPaymentInput> {
  const RecordPaymentReceivedUseCase(this._repository);

  final PartyRepository _repository;

  @override
  Future<Result<void>> call(RecordPaymentInput input) async {
    if (input.partyId.trim().isEmpty) {
      return const Error(ValidationFailure('Naam chuniye'));
    }
    if (input.amount <= 0) {
      return const Error(ValidationFailure('Raashi zero se zyada honi chahiye'));
    }
    return _repository.recordPaymentReceived(input);
  }
}

final class RecordPaymentPaidUseCase implements UseCase<void, RecordPaymentInput> {
  const RecordPaymentPaidUseCase(this._repository);

  final PartyRepository _repository;

  @override
  Future<Result<void>> call(RecordPaymentInput input) async {
    if (input.partyId.trim().isEmpty) {
      return const Error(ValidationFailure('Naam chuniye'));
    }
    if (input.amount <= 0) {
      return const Error(ValidationFailure('Raashi zero se zyada honi chahiye'));
    }
    return _repository.recordPaymentPaid(input);
  }
}
