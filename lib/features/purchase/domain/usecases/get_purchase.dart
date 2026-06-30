import '../../../../core/errors/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/purchase_invoice.dart';
import '../repositories/purchase_repository.dart';

final class GetPurchaseUseCase implements UseCase<PurchaseInvoice?, String> {
  const GetPurchaseUseCase(this._repository);

  final PurchaseRepository _repository;

  @override
  Future<Result<PurchaseInvoice?>> call(String id) {
    return _repository.getPurchase(id);
  }
}
