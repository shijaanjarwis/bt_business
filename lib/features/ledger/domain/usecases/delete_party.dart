import '../../../../core/errors/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/party_repository.dart';

final class DeletePartyUseCase implements UseCase<void, String> {
  const DeletePartyUseCase(this._repository);

  final PartyRepository _repository;

  @override
  Future<Result<void>> call(String id) {
    return _repository.deleteParty(id);
  }
}
