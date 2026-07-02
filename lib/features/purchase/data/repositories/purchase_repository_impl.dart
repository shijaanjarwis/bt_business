import '../../../../core/accounting/payment_modes.dart';
import '../../../../core/errors/exception_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/purchase_invoice.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../datasources/purchase_local_datasource.dart';
import '../services/purchase_posting_service.dart';

final class PurchaseRepositoryImpl implements PurchaseRepository {
  const PurchaseRepositoryImpl(this._localDataSource, this._postingService);

  final PurchaseLocalDataSource _localDataSource;
  final PurchasePostingService _postingService;

  @override
  Future<Result<List<PurchaseInvoice>>> getPurchases({
    DateTime? fromDate,
    DateTime? toDate,
    PaymentMode? paymentMode,
    double? minDueAmount,
    double? minPaidAmount,
  }) async {
    try {
      final purchases = await _localDataSource.fetchPurchases(
        fromDate: fromDate,
        toDate: toDate,
        paymentMode: paymentMode,
        minDueAmount: minDueAmount,
        minPaidAmount: minPaidAmount,
      );
      return Success(purchases);
    } catch (error, stackTrace) {
      return Error(ExceptionMapper.map(error, stackTrace));
    }
  }

  @override
  Future<Result<List<PurchaseInvoice>>> searchPurchases(
    String query, {
    DateTime? fromDate,
    DateTime? toDate,
    PaymentMode? paymentMode,
    double? minDueAmount,
    double? minPaidAmount,
  }) async {
    try {
      final purchases = await _localDataSource.searchPurchases(
        query,
        fromDate: fromDate,
        toDate: toDate,
        paymentMode: paymentMode,
        minDueAmount: minDueAmount,
        minPaidAmount: minPaidAmount,
      );
      return Success(purchases);
    } catch (error, stackTrace) {
      return Error(ExceptionMapper.map(error, stackTrace));
    }
  }

  @override
  Future<Result<PurchaseInvoice?>> getPurchase(String id) async {
    try {
      final purchase = await _localDataSource.fetchPurchase(id);
      return Success(purchase);
    } catch (error, stackTrace) {
      return Error(ExceptionMapper.map(error, stackTrace));
    }
  }

  @override
  Future<Result<PurchaseInvoice>> savePurchase(SavePurchaseInput input) async {
    try {
      final businessId = await _localDataSource.currentBusinessId();
      if (businessId == null) {
        return const Error(
          ValidationFailure('Set up your business profile before creating purchases'),
        );
      }

      final saved = await _postingService.save(businessId: businessId, input: input);
      return Success(saved);
    } catch (error, stackTrace) {
      return Error(ExceptionMapper.map(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> deletePurchase(String id) async {
    try {
      await _postingService.delete(id);
      return const Success(null);
    } catch (error, stackTrace) {
      return Error(ExceptionMapper.map(error, stackTrace));
    }
  }
}
