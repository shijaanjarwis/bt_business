import '../../../../core/errors/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/sale_invoice.dart';
import '../repositories/sale_repository.dart';

final class GetSaleUseCase implements UseCase<SaleInvoice?, String> {
  const GetSaleUseCase(this._repository);

  final SaleRepository _repository;

  @override
  Future<Result<SaleInvoice?>> call(String id) {
    return _repository.getSale(id);
  }
}
