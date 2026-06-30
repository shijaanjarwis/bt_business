import '../../../../core/accounting/payment_modes.dart';
import '../../../../core/errors/exception_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/sale_entry.dart';
import '../../domain/repositories/sale_repository.dart';
import '../datasources/sale_local_datasource.dart';
import '../services/sale_posting_service.dart';

final class SaleRepositoryImpl implements SaleRepository {
  const SaleRepositoryImpl(this._localDataSource, this._postingService);

  final SaleLocalDataSource _localDataSource;
  final SalePostingService _postingService;

  @override
  Future<Result<List<SaleEntry>>> getSales({
    DateTime? fromDate,
    DateTime? toDate,
    PaymentMode? paymentMode,
  }) async {
    try {
      final sales = await _localDataSource.fetchSales(
        fromDate: fromDate,
        toDate: toDate,
        paymentMode: paymentMode,
      );
      return Success(sales);
    } catch (error, stackTrace) {
      return Error(ExceptionMapper.map(error, stackTrace));
    }
  }

  @override
  Future<Result<List<SaleEntry>>> searchSales(String query) async {
    try {
      final sales = await _localDataSource.searchSales(query);
      return Success(sales);
    } catch (error, stackTrace) {
      return Error(ExceptionMapper.map(error, stackTrace));
    }
  }

  @override
  Future<Result<SaleEntry?>> getSale(String id) async {
    try {
      final sale = await _localDataSource.fetchSale(id);
      return Success(sale);
    } catch (error, stackTrace) {
      return Error(ExceptionMapper.map(error, stackTrace));
    }
  }

  @override
  Future<Result<SaleEntry>> saveSale(SaveSaleInput input) async {
    try {
      final businessId = await _localDataSource.currentBusinessId();
      if (businessId == null) {
        return const Error(
          ValidationFailure('Pehle apni dukaan ka naam set karein'),
        );
      }

      final saved = await _postingService.save(businessId: businessId, input: input);
      return Success(saved);
    } catch (error, stackTrace) {
      return Error(ExceptionMapper.map(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> deleteSale(String id) async {
    try {
      await _postingService.delete(id);
      return const Success(null);
    } catch (error, stackTrace) {
      return Error(ExceptionMapper.map(error, stackTrace));
    }
  }
}
