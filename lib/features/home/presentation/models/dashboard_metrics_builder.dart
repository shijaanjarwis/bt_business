import 'package:flutter/material.dart';
import '../../../../core/utils/date_formatter.dart';
import '../models/dashboard_summary.dart';
import 'dashboard_metric.dart';

/// Maps [DashboardSummary] into ordered dashboard cards.
abstract final class DashboardMetricsBuilder {
  static List<DashboardMetric> fromSummary(DashboardSummary summary) {
    return [
      DashboardMetric(
        englishLabel: "Today's Profit",
        hindiLabel: 'Aaj Ka Profit',
        amount: summary.todaysProfit,
        icon: Icons.trending_up_rounded,
        isHero: true,
        fullWidth: true,
      ),
      DashboardMetric(
        englishLabel: "Today's Sales",
        hindiLabel: 'Aaj Ki Sale',
        amount: summary.todaysSales,
        icon: Icons.point_of_sale_rounded,
      ),
      DashboardMetric(
        englishLabel: "Today's Purchase",
        hindiLabel: 'Aaj Ki Kharid',
        amount: summary.todaysPurchase,
        icon: Icons.shopping_cart_rounded,
      ),
      DashboardMetric(
        englishLabel: 'Cash in Hand',
        hindiLabel: 'Haath Me Cash',
        amount: summary.cashInHand,
        icon: Icons.payments_rounded,
      ),
      DashboardMetric(
        englishLabel: 'Amount in Bank',
        hindiLabel: 'Bank Me Paise',
        amount: summary.amountInBank,
        icon: Icons.account_balance_rounded,
      ),
      DashboardMetric(
        englishLabel: "Today's Receivables",
        hindiLabel: 'Aaj Kis Kis Se Paise Lene Hain',
        amount: summary.todaysReceivables,
        icon: Icons.call_received_rounded,
        fullWidth: true,
        subtitle: summary.receivableCount > 0
            ? '${summary.receivableCount} log se lene hain'
            : 'Abhi kisi se paise lene nahi hain',
      ),
      DashboardMetric(
        englishLabel: "Today's Payables",
        hindiLabel: 'Aaj Kis Kis Ko Paise Dene Hain',
        amount: summary.todaysPayables,
        icon: Icons.call_made_rounded,
        fullWidth: true,
        subtitle: summary.payableCount > 0
            ? '${summary.payableCount} log ko dene hain'
            : 'Abhi kisi ko paise dene nahi hain',
      ),
      DashboardMetric(
        englishLabel: 'Payment Received',
        hindiLabel: 'Payment Mili',
        amount: summary.paymentReceived,
        icon: Icons.south_west_rounded,
      ),
      DashboardMetric(
        englishLabel: 'Payment Paid',
        hindiLabel: 'Payment Di',
        amount: summary.paymentPaid,
        icon: Icons.north_east_rounded,
      ),
      DashboardMetric(
        englishLabel: 'Goods Sold',
        hindiLabel: 'Maal Becha',
        amount: summary.goodsSold,
        icon: Icons.inventory_2_outlined,
      ),
      DashboardMetric(
        englishLabel: 'Goods Purchased',
        hindiLabel: 'Maal Kharida',
        amount: summary.goodsPurchased,
        icon: Icons.local_shipping_outlined,
      ),
    ];
  }

  static String todayLabel() => DateFormatter.displayDate(DateTime.now());
}
