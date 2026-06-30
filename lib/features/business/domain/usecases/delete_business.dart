import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/business_repository.dart';

class DeleteBusinessParams {
  const DeleteBusinessParams({required this.id});

  final String id;
}

final class DeleteBusinessUseCase
    implements UseCase<void, DeleteBusinessParams> {
  const DeleteBusinessUseCase(this._repository);

  final BusinessRepository _repository;

  @override
  Future<Result<void>> call(DeleteBusinessParams params) async {
    if (params.id.trim().isEmpty) {
      return const Error(ValidationFailure('Business id is required'));
    }

    return _repository.deleteBusiness(params.id);
  }
}
