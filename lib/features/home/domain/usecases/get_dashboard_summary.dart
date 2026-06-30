import '../../../../core/errors/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/dashboard_summary.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardSummaryParams {
  const GetDashboardSummaryParams({this.asOf});

  final DateTime? asOf;
}

final class GetDashboardSummaryUseCase
    implements UseCase<DashboardSummary, GetDashboardSummaryParams> {
  const GetDashboardSummaryUseCase(this._repository);

  final DashboardRepository _repository;

  @override
  Future<Result<DashboardSummary>> call(GetDashboardSummaryParams params) {
    return _repository.getDashboardSummary(asOf: params.asOf);
  }
}
