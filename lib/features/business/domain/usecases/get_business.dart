import '../../../../core/errors/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/business.dart';
import '../repositories/business_repository.dart';

final class GetBusinessUseCase implements UseCase<Business?, NoParams> {
  const GetBusinessUseCase(this._repository);

  final BusinessRepository _repository;

  @override
  Future<Result<Business?>> call(NoParams params) => _repository.getBusiness();
}
