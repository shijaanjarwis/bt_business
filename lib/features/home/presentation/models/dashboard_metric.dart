import 'package:flutter/material.dart';

/// A single metric shown on the home dashboard.
class DashboardMetric {
  const DashboardMetric({
    required this.englishLabel,
    required this.hindiLabel,
    required this.amount,
    required this.icon,
    this.isHero = false,
    this.fullWidth = false,
    this.subtitle,
  });

  final String englishLabel;
  final String hindiLabel;
  final double amount;
  final IconData icon;
  final bool isHero;
  final bool fullWidth;
  final String? subtitle;
}
