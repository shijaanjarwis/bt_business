import '../../../../core/errors/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/purchase_repository.dart';

final class DeletePurchaseUseCase implements UseCase<void, String> {
  const DeletePurchaseUseCase(this._repository);

  final PurchaseRepository _repository;

  @override
  Future<Result<void>> call(String id) {
    return _repository.deletePurchase(id);
  }
}
