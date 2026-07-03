import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/utils/register_date_period.dart';
import '../models/dashboard_metric.dart';
import '../models/dashboard_summary_kind.dart';
import '../providers/dashboard_summary_providers.dart';

/// Opens the matching dashboard summary detail screen.
abstract final class DashboardRegisterNavigation {
  static void open(BuildContext context, WidgetRef ref, DashboardMetric metric) {
    final kind = DashboardSummaryKind.fromTarget(metric.target);
    ref.read(dashboardSummarySearchProvider(kind).notifier).state = '';
    ref.read(dashboardSummaryDatePeriodProvider(kind).notifier).state =
        kind == DashboardSummaryKind.cashInHand
            ? RegisterDatePeriod.thisMonth
            : RegisterDatePeriod.today;
    ref.read(dashboardSummaryCustomStartProvider(kind).notifier).state = null;
    ref.read(dashboardSummaryCustomEndProvider(kind).notifier).state = null;
    context.push(RouteNames.dashboardSummaryDetailPath(kind.routeSlug));
  }
}
