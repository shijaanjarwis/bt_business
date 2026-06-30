import '../../../../core/errors/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/party.dart';
import '../repositories/party_repository.dart';

final class SearchPartiesUseCase
    implements UseCase<List<Party>, SearchPartiesParams> {
  const SearchPartiesUseCase(this._repository);

  final PartyRepository _repository;

  @override
  Future<Result<List<Party>>> call(SearchPartiesParams params) {
    return _repository.searchParties(
      params.query,
      activeOnly: params.activeOnly,
    );
  }
}

class SearchPartiesParams {
  const SearchPartiesParams({
    required this.query,
    this.activeOnly = false,
  });

  final String query;
  final bool activeOnly;
}
