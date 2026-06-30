import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/di/data_revision.dart';
import '../../data/datasources/dashboard_local_datasource.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/usecases/get_dashboard_summary.dart';

final dashboardLocalDataSourceProvider = Provider<DashboardLocalDataSource>((ref) {
  final database = ref.watch(appDatabaseProvider).requireValue;
  return DashboardLocalDataSource(database);
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.watch(dashboardLocalDataSourceProvider));
});

final getDashboardSummaryUseCaseProvider = Provider<GetDashboardSummaryUseCase>((ref) {
  return GetDashboardSummaryUseCase(ref.watch(dashboardRepositoryProvider));
});

/// Loads today's dashboard snapshot from SQLite.
class DashboardNotifier extends AsyncNotifier<DashboardSummary> {
  @override
  Future<DashboardSummary> build() async {
    ref.watch(dataRevisionProvider);

    final result = await ref.read(getDashboardSummaryUseCaseProvider)(
      const GetDashboardSummaryParams(),
    );

    if (result.isFailure) {
      throw result.failureOrNull!;
    }

    return result.valueOrNull ?? DashboardSummary.zero;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(getDashboardSummaryUseCaseProvider)(
        const GetDashboardSummaryParams(),
      );
      if (result.isFailure) throw result.failureOrNull!;
      return result.valueOrNull ?? DashboardSummary.zero;
    });
  }
}

final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardSummary>(
  DashboardNotifier.new,
);
