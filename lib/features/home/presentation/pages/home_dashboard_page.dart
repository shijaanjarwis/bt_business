import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/animations/fade_slide_in.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../models/dashboard_metrics_builder.dart';
import '../models/dashboard_metric.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/bt_business_logo.dart';
import '../widgets/dashboard_metric_card.dart';
import '../widgets/dashboard_section_header.dart';

/// BT Business home dashboard — iPhone-first production UI.
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
          onSalesTap: () => context.push(RouteNames.sales),
          onNewSaleTap: () => context.push(RouteNames.salesNew),
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
    required this.onNewSaleTap,
  });

  final List<DashboardMetric> metrics;
  final Future<void> Function() onRefresh;
  final VoidCallback onSalesTap;
  final VoidCallback onNewSaleTap;

  @override
  Widget build(BuildContext context) {
    final hero = metrics.first;
    final today = metrics.sublist(1, 3);
    final cashBank = metrics.sublist(3, 5);
    final receivablePayable = metrics.sublist(5, 7);
    final payments = metrics.sublist(7, 9);
    final goods = metrics.sublist(9, 11);

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
                        DashboardMetricsBuilder.todayLabel(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: ColorPalette.labelSecondary,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeSlideIn(
                      index: 2,
                      child: DashboardMetricCard(metric: hero),
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
                  const FadeSlideIn(
                    index: 3,
                    child: DashboardSectionHeader(title: 'TODAY'),
                  ),
                  FadeSlideIn(
                    index: 4,
                    child: _MetricPairRow(
                      left: today[0],
                      right: today[1],
                      onLeftTap: onSalesTap,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const FadeSlideIn(
                    index: 5,
                    child: DashboardSectionHeader(title: 'CASH & BANK'),
                  ),
                  FadeSlideIn(
                    index: 6,
                    child: _MetricPairRow(
                      left: cashBank[0],
                      right: cashBank[1],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const FadeSlideIn(
                    index: 7,
                    child: DashboardSectionHeader(title: 'LENA / DENA'),
                  ),
                  FadeSlideIn(
                    index: 8,
                    child: DashboardMetricCard(metric: receivablePayable[0]),
                  ),
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    index: 9,
                    child: DashboardMetricCard(metric: receivablePayable[1]),
                  ),
                  const SizedBox(height: 22),
                  const FadeSlideIn(
                    index: 10,
                    child: DashboardSectionHeader(title: 'PAYMENTS'),
                  ),
                  FadeSlideIn(
                    index: 11,
                    child: _MetricPairRow(left: payments[0], right: payments[1]),
                  ),
                  const SizedBox(height: 22),
                  const FadeSlideIn(
                    index: 12,
                    child: DashboardSectionHeader(title: 'GOODS'),
                  ),
                  FadeSlideIn(
                    index: 13,
                    child: _MetricPairRow(left: goods[0], right: goods[1]),
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
  });

  final DashboardMetric left;
  final DashboardMetric right;
  final VoidCallback? onLeftTap;

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
        Expanded(child: DashboardMetricCard(metric: right)),
      ],
    );
  }
}
