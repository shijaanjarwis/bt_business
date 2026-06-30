import 'package:flutter/material.dart';
import '../../domain/entities/dashboard_summary.dart';
import 'dashboard_metric.dart';

/// Six simple daily cards for shopkeepers.
abstract final class DashboardMetricsBuilder {
  static List<DashboardMetric> fromSummary(DashboardSummary summary) {
    return [
      DashboardMetric(
        englishLabel: 'Cash in Hand',
        hindiLabel: 'Haath mein cash',
        amount: summary.cashInHand,
        icon: Icons.payments_rounded,
        fullWidth: true,
      ),
      DashboardMetric(
        englishLabel: 'Lena Hai',
        hindiLabel: 'Lena hai',
        amount: summary.todaysReceivables,
        icon: Icons.call_received_rounded,
        subtitle: summary.receivableCount > 0
            ? '${summary.receivableCount} party'
            : null,
      ),
      DashboardMetric(
        englishLabel: 'Dena Hai',
        hindiLabel: 'Dena hai',
        amount: summary.todaysPayables,
        icon: Icons.call_made_rounded,
        subtitle: summary.payableCount > 0
            ? '${summary.payableCount} party'
            : null,
      ),
      DashboardMetric(
        englishLabel: 'Aaj ki Bikri',
        hindiLabel: 'Aaj ki bikri',
        amount: summary.todaysSales,
        icon: Icons.sell_outlined,
      ),
      DashboardMetric(
        englishLabel: 'Aaj ki Kharid',
        hindiLabel: 'Aaj ki kharid',
        amount: summary.todaysPurchase,
        icon: Icons.shopping_bag_outlined,
      ),
      DashboardMetric(
        englishLabel: 'Aaj ka Kharch',
        hindiLabel: 'Aaj ka kharch',
        amount: summary.todaysExpenses,
        icon: Icons.receipt_long_rounded,
      ),
    ];
  }
}
