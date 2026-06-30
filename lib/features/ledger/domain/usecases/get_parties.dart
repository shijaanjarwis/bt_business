import '../../../../core/errors/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/party.dart';
import '../repositories/party_repository.dart';

final class GetPartiesUseCase implements UseCase<List<Party>, GetPartiesParams> {
  const GetPartiesUseCase(this._repository);

  final PartyRepository _repository;

  @override
  Future<Result<List<Party>>> call(GetPartiesParams params) {
    return _repository.getParties(activeOnly: params.activeOnly);
  }
}

class GetPartiesParams {
  const GetPartiesParams({this.activeOnly = false});

  final bool activeOnly;
}
