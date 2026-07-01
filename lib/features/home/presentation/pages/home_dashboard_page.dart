import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/branding/developer_footer.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../business/presentation/providers/business_providers.dart';
import '../../../items/domain/entities/item.dart';
import '../../../reports/data/datasources/transaction_history_local_datasource.dart';
import '../models/dashboard_metric.dart';
import '../models/dashboard_metrics_builder.dart';
import '../providers/dashboard_extras_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_low_stock_section.dart';
import '../widgets/dashboard_quick_actions.dart';
import '../widgets/dashboard_recent_activity_section.dart';
import '../widgets/dashboard_summary_grid.dart';

/// Daily business overview for shopkeepers and wholesalers.
class HomeDashboardPage extends ConsumerWidget {
  const HomeDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final businessAsync = ref.watch(businessProfileProvider);
    final recentAsync = ref.watch(dashboardRecentActivityProvider);
    final lowStockAsync = ref.watch(dashboardLowStockProvider);

    return Scaffold(
      backgroundColor: ColorPalette.background,
      body: dashboardAsync.when(
        loading: () => const AppLoadingView(),
        error: (error, _) => AppErrorView(
          title: 'Dashboard load nahi ho paya',
          message: error.toString(),
          actionLabel: 'Try Again',
          onAction: () => ref.invalidate(dashboardProvider),
          icon: Icons.cloud_off_rounded,
        ),
        data: (summary) {
          final businessName = businessAsync.maybeWhen(
            data: (business) => business?.name.trim().isNotEmpty == true
                ? business!.name
                : 'Apka Business',
            orElse: () => 'Apka Business',
          );
          final metrics = DashboardMetricsBuilder.fromSummary(summary);
          final recentEntries = recentAsync.valueOrNull ?? const [];
          final lowStockItems = lowStockAsync.valueOrNull ?? const [];

          return _DashboardContent(
            businessName: businessName,
            metrics: metrics,
            recentEntries: recentEntries,
            lowStockItems: lowStockItems,
            onRefresh: () async {
              ref.invalidate(dashboardProvider);
              ref.invalidate(dashboardRecentActivityProvider);
              ref.invalidate(dashboardLowStockProvider);
              ref.invalidate(businessProfileProvider);
              await ref.read(dashboardProvider.future);
            },
            onProfileTap: () => context.push(
              '${RouteNames.businessProfile}?mode=edit',
            ),
          );
        },
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.businessName,
    required this.metrics,
    required this.recentEntries,
    required this.lowStockItems,
    required this.onRefresh,
    required this.onProfileTap,
  });

  final String businessName;
  final List<DashboardMetric> metrics;
  final List<TransactionHistoryEntry> recentEntries;
  final List<Item> lowStockItems;
  final Future<void> Function() onRefresh;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: ColorPalette.purple,
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DashboardHeader(
                businessName: businessName,
                onProfileTap: onProfileTap,
              ),
              const SizedBox(height: 24),
              DashboardSummaryGrid(metrics: metrics),
              const SizedBox(height: 28),
              const DashboardQuickActions(),
              if (lowStockItems.isNotEmpty) ...[
                const SizedBox(height: 28),
                DashboardLowStockSection(items: lowStockItems),
              ],
              const SizedBox(height: 28),
              DashboardRecentActivitySection(entries: recentEntries),
              const DeveloperFooter(
                padding: EdgeInsets.fromLTRB(0, 28, 0, 8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
