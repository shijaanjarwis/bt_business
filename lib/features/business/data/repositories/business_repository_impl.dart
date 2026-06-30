import '../../../../core/errors/exception_mapper.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/business.dart';
import '../../domain/repositories/business_repository.dart';
import '../datasources/business_local_datasource.dart';

final class BusinessRepositoryImpl implements BusinessRepository {
  const BusinessRepositoryImpl(this._localDataSource);

  final BusinessLocalDataSource _localDataSource;

  @override
  Future<Result<Business?>> getBusiness() async {
    try {
      final business = await _localDataSource.fetchBusiness();
      return Success(business);
    } catch (error, stackTrace) {
      return Error(ExceptionMapper.map(error, stackTrace));
    }
  }

  @override
  Future<Result<Business>> saveBusiness(Business business) async {
    try {
      final saved = await _localDataSource.upsertBusiness(business);
      return Success(saved);
    } catch (error, stackTrace) {
      return Error(ExceptionMapper.map(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> deleteBusiness(String id) async {
    try {
      await _localDataSource.removeBusiness(id);
      return const Success(null);
    } catch (error, stackTrace) {
      return Error(ExceptionMapper.map(error, stackTrace));
    }
  }
}
