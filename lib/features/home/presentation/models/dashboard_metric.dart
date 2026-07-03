import 'package:flutter/material.dart';

enum DashboardMetricTarget {
  todaySales,
  todayPurchase,
  todayCashReceived,
  todayCredit,
  cashInHand,
}

/// A single metric shown on the home dashboard.
class DashboardMetric {
  const DashboardMetric({
    required this.englishLabel,
    required this.hindiLabel,
    required this.amount,
    required this.icon,
    required this.target,
    this.isHero = false,
    this.fullWidth = false,
    this.subtitle,
  });

  final String englishLabel;
  final String hindiLabel;
  final double amount;
  final IconData icon;
  final DashboardMetricTarget target;
  final bool isHero;
  final bool fullWidth;
  final String? subtitle;
}
