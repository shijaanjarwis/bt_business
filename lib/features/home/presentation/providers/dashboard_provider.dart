import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard_summary.dart';

/// Loads today's dashboard snapshot.
///
/// Returns zeroed values until SQLite ledger integration is wired.
class DashboardNotifier extends AsyncNotifier<DashboardSummary> {
  @override
  Future<DashboardSummary> build() => _loadSummary();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _loadSummary());
  }

  Future<DashboardSummary> _loadSummary() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return const DashboardSummary();
  }
}

final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardSummary>(
  DashboardNotifier.new,
);
