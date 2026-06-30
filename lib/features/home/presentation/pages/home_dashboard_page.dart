import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/animations/fade_slide_in.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../models/dashboard_metrics_builder.dart';
import '../models/dashboard_metric.dart';
import '../providers/dashboard_provider.dart';
import '../../../ledger/presentation/providers/party_providers.dart';
import '../widgets/bt_business_logo.dart';
import '../widgets/dashboard_metric_card.dart';
import '../widgets/dashboard_quick_actions.dart';

/// Daily register summary for the shopkeeper dashboard.
class HomeDashboardPage extends ConsumerWidget {
  const HomeDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

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
        data: (summary) => _DashboardContent(
          metrics: DashboardMetricsBuilder.fromSummary(summary),
          onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
          onSalesTap: () => context.go(RouteNames.sales),
          onPurchasesTap: () => context.go(RouteNames.purchases),
          onExpenseTap: () => context.push(RouteNames.paymentsExpense),
          onLenaTap: () {
            ref.read(partyBalanceFilterProvider.notifier).state =
                PartyBalanceFilter.lena;
            context.go(RouteNames.ledger);
          },
          onDenaTap: () {
            ref.read(partyBalanceFilterProvider.notifier).state =
                PartyBalanceFilter.dena;
            context.go(RouteNames.ledger);
          },
          onHistoryTap: () => context.push(RouteNames.history),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.metrics,
    required this.onRefresh,
    required this.onSalesTap,
    required this.onPurchasesTap,
    required this.onExpenseTap,
    required this.onLenaTap,
    required this.onDenaTap,
    required this.onHistoryTap,
  });

  final List<DashboardMetric> metrics;
  final Future<void> Function() onRefresh;
  final VoidCallback onSalesTap;
  final VoidCallback onPurchasesTap;
  final VoidCallback onExpenseTap;
  final VoidCallback onLenaTap;
  final VoidCallback onDenaTap;
  final VoidCallback onHistoryTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: ColorPalette.purple,
        onRefresh: onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeSlideIn(
                      index: 0,
                      child: Row(
                        children: [
                          const Expanded(child: BtBusinessLogo()),
                          IconButton(
                            tooltip: 'Business Profile',
                            onPressed: () => context.push(
                              '${RouteNames.businessProfile}?mode=edit',
                            ),
                            icon: const Icon(
                              Icons.storefront_rounded,
                              color: ColorPalette.purple,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeSlideIn(
                      index: 1,
                      child: Text(
                        DateFormatter.displayDate(DateTime.now()),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: ColorPalette.labelSecondary,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const FadeSlideIn(
                      index: 2,
                      child: DashboardQuickActions(),
                    ),
                    const SizedBox(height: 16),
                    FadeSlideIn(
                      index: 3,
                      child: OutlinedButton.icon(
                        onPressed: onHistoryTap,
                        icon: const Icon(Icons.history_rounded, color: ColorPalette.purple),
                        label: const Text('Poora Record · History'),
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  FadeSlideIn(
                    index: 4,
                    child: DashboardMetricCard(metric: metrics[0]),
                  ),
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    index: 5,
                    child: _MetricPairRow(
                      left: metrics[1],
                      right: metrics[2],
                      onLeftTap: onLenaTap,
                      onRightTap: onDenaTap,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    index: 6,
                    child: _MetricPairRow(
                      left: metrics[3],
                      right: metrics[4],
                      onLeftTap: onSalesTap,
                      onRightTap: onPurchasesTap,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    index: 7,
                    child: DashboardMetricCard(
                      metric: metrics[5],
                      onTap: onExpenseTap,
                    ),
                  ),
                  const SizedBox(height: 120),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricPairRow extends StatelessWidget {
  const _MetricPairRow({
    required this.left,
    required this.right,
    this.onLeftTap,
    this.onRightTap,
  });

  final DashboardMetric left;
  final DashboardMetric right;
  final VoidCallback? onLeftTap;
  final VoidCallback? onRightTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DashboardMetricCard(
            metric: left,
            onTap: onLeftTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DashboardMetricCard(
            metric: right,
            onTap: onRightTap,
          ),
        ),
      ],
    );
  }
}
