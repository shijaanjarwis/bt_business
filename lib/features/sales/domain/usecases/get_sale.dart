import '../../../../core/errors/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/sale_entry.dart';
import '../repositories/sale_repository.dart';

final class GetSaleUseCase implements UseCase<SaleEntry?, String> {
  const GetSaleUseCase(this._repository);

  final SaleRepository _repository;

  @override
  Future<Result<SaleEntry?>> call(String id) {
    return _repository.getSale(id);
  }
}
