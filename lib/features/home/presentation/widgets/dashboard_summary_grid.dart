import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';
import '../models/dashboard_metric.dart';
import '../utils/dashboard_register_navigation.dart';

/// 2×2 grid of today's summary cards — tap opens filtered register.
class DashboardSummaryGrid extends ConsumerWidget {
  const DashboardSummaryGrid({
    super.key,
    required this.metrics,
  });

  final List<DashboardMetric> metrics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BilingualLabel(
          english: "Today's Summary",
          hindi: 'Aaj ka Hisaab',
          compact: true,
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.08,
          children: metrics
              .map((metric) => _SummaryCard(metric: metric, ref: ref))
              .toList(),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.metric,
    required this.ref,
  });

  final DashboardMetric metric;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorPalette.cardSurface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => DashboardRegisterNavigation.open(context, ref, metric),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: ColorPalette.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(metric.icon, size: 22, color: ColorPalette.purple),
              const Spacer(),
              BilingualLabel(
                english: metric.englishLabel,
                hindi: metric.hindiLabel,
                compact: true,
              ),
              const SizedBox(height: 10),
              Text(
                CurrencyFormatter.format(metric.amount),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: ColorPalette.labelPrimary,
                  letterSpacing: -0.5,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
