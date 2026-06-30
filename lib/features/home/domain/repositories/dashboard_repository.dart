import '../../../../core/errors/result.dart';
import '../entities/dashboard_summary.dart';

/// Reads aggregated dashboard metrics from persistent storage.
abstract interface class DashboardRepository {
  Future<Result<DashboardSummary>> getDashboardSummary({DateTime? asOf});
}
