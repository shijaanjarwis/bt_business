import 'package:flutter/material.dart';

import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/animations/animated_counter.dart';
import '../models/dashboard_metric.dart';
import 'bilingual_label.dart';

/// Apple-style rounded metric card for the home dashboard.
class DashboardMetricCard extends StatelessWidget {
  const DashboardMetricCard({
    super.key,
    required this.metric,
    this.animate = true,
  });

  final DashboardMetric metric;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    if (metric.isHero) {
      return _HeroCard(metric: metric, animate: animate);
    }
    return _StandardCard(metric: metric, animate: animate);
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.metric, required this.animate});

  final DashboardMetric metric;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    const valueStyle = TextStyle(
      fontSize: 38,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      letterSpacing: -1.2,
      height: 1,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ColorPalette.purple, ColorPalette.purpleDark],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: ColorPalette.purple.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(metric.icon, color: Colors.white, size: 22),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Today',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          BilingualLabel(
            english: metric.englishLabel,
            hindi: metric.hindiLabel,
            englishStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xF2FFFFFF),
              letterSpacing: -0.3,
            ),
            hindiStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xB3FFFFFF),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          animate
              ? AnimatedCounter(value: metric.amount, style: valueStyle)
              : Text(
                  CurrencyFormatter.format(metric.amount),
                  style: valueStyle,
                ),
        ],
      ),
    );
  }
}

class _StandardCard extends StatelessWidget {
  const _StandardCard({required this.metric, required this.animate});

  final DashboardMetric metric;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    const valueStyle = TextStyle(
      fontSize: 21,
      fontWeight: FontWeight.w700,
      color: Color(0xFF1C1C1E),
      letterSpacing: -0.6,
      height: 1,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorPalette.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorPalette.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  metric.icon,
                  size: 18,
                  color: ColorPalette.purple,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: BilingualLabel(
                  english: metric.englishLabel,
                  hindi: metric.hindiLabel,
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          animate
              ? AnimatedCounter(value: metric.amount, style: valueStyle)
              : Text(
                  CurrencyFormatter.format(metric.amount),
                  style: valueStyle,
                ),
          if (metric.subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              metric.subtitle!,
              style: const TextStyle(
                fontSize: 11,
                color: ColorPalette.labelSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
