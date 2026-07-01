import 'package:flutter/material.dart';

import '../../domain/entities/dashboard_summary.dart';
import 'dashboard_metric.dart';

/// Four daily summary cards for the shopkeeper dashboard.
abstract final class DashboardMetricsBuilder {
  static List<DashboardMetric> fromSummary(DashboardSummary summary) {
    return [
      DashboardMetric(
        englishLabel: "Today's Sale",
        hindiLabel: 'Aaj Ki Bikri',
        amount: summary.todaysSales,
        icon: Icons.sell_outlined,
        target: DashboardMetricTarget.todaySales,
      ),
      DashboardMetric(
        englishLabel: "Today's Cash",
        hindiLabel: 'Aaj Cash Mila',
        amount: summary.todaysCashReceived,
        icon: Icons.payments_rounded,
        target: DashboardMetricTarget.todayCash,
      ),
      DashboardMetric(
        englishLabel: "Today's Credit",
        hindiLabel: 'Aaj Udhaar Bana',
        amount: summary.todaysUdhaarCreated,
        icon: Icons.schedule_rounded,
        target: DashboardMetricTarget.todayCredit,
      ),
      DashboardMetric(
        englishLabel: 'Cash In Hand',
        hindiLabel: 'Haath Mein Cash',
        amount: summary.cashInHand,
        icon: Icons.account_balance_wallet_outlined,
        target: DashboardMetricTarget.cashInHand,
      ),
    ];
  }
}
