import '../../../../core/errors/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/party.dart';
import '../repositories/party_repository.dart';

final class GetPartyUseCase implements UseCase<Party?, String> {
  const GetPartyUseCase(this._repository);

  final PartyRepository _repository;

  @override
  Future<Result<Party?>> call(String id) {
    return _repository.getParty(id);
  }
}
