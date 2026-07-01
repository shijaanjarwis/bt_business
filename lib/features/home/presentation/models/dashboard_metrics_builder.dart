import 'package:flutter/material.dart';

import '../../domain/entities/dashboard_summary.dart';
import 'dashboard_metric.dart';

/// Four daily summary cards for the shopkeeper dashboard.
abstract final class DashboardMetricsBuilder {
  static List<DashboardMetric> fromSummary(DashboardSummary summary) {
    return [
      DashboardMetric(
        englishLabel: 'Aaj ki Bikri',
        hindiLabel: 'Aaj ki bikri',
        amount: summary.todaysSales,
        icon: Icons.sell_outlined,
      ),
      DashboardMetric(
        englishLabel: 'Aaj Cash Mila',
        hindiLabel: 'Aaj cash mila',
        amount: summary.todaysCashReceived,
        icon: Icons.payments_rounded,
      ),
      DashboardMetric(
        englishLabel: 'Aaj Udhaar Bana',
        hindiLabel: 'Aaj udhaar bana',
        amount: summary.todaysUdhaarCreated,
        icon: Icons.schedule_rounded,
      ),
      DashboardMetric(
        englishLabel: 'Cash in Hand',
        hindiLabel: 'Haath mein cash',
        amount: summary.cashInHand,
        icon: Icons.account_balance_wallet_outlined,
      ),
    ];
  }
}
