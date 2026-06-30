import '../../../../core/errors/exception_mapper.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_local_datasource.dart';

final class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl(this._localDataSource);

  final DashboardLocalDataSource _localDataSource;

  @override
  Future<Result<DashboardSummary>> getDashboardSummary({DateTime? asOf}) async {
    try {
      final summary = await _localDataSource.fetchSummary(asOf: asOf);
      return Success(summary);
    } catch (error, stackTrace) {
      return Error(ExceptionMapper.map(error, stackTrace));
    }
  }
}
