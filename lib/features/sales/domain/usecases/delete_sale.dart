import '../../../../core/errors/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/sale_repository.dart';

final class DeleteSaleUseCase implements UseCase<void, String> {
  const DeleteSaleUseCase(this._repository);

  final SaleRepository _repository;

  @override
  Future<Result<void>> call(String id) {
    return _repository.deleteSale(id);
  }
}
