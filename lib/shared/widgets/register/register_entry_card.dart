import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_text_theme.dart';
import '../../../core/theme/color_palette.dart';
import '../../../core/theme/transaction_badge_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../badges/app_transaction_badge.dart';

/// One metric row on a register card — English label + formatted value.
class RegisterEntryMetric {
  const RegisterEntryMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;
}

/// Shared register list card — sale, purchase, payment, and history.
class RegisterEntryCard extends StatelessWidget {
  const RegisterEntryCard({
    super.key,
    required this.partyTitle,
    required this.amount,
    required this.date,
    required this.createdAt,
    required this.onTap,
    this.metrics = const [],
    this.badgeKind,
    this.subtitle,
    this.showAmount = true,
  });

  final String partyTitle;
  final double amount;
  final DateTime date;
  final DateTime createdAt;
  final VoidCallback onTap;
  final List<RegisterEntryMetric> metrics;
  final TransactionBadgeKind? badgeKind;
  final String? subtitle;
  final bool showAmount;

  @override
  Widget build(BuildContext context) {
    final timeLabel = DateFormat('h:mm a').format(createdAt);
    final appText = context.appText;

    return Material(
      color: ColorPalette.cardSurface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          partyTitle,
                          style: appText.listTitle.copyWith(fontSize: 15),
                        ),
                        if (badgeKind != null) ...[
                          const SizedBox(height: 8),
                          AppTransactionBadge(kind: badgeKind!, compact: true),
                        ],
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            subtitle!,
                            style: appText.caption,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (showAmount)
                    Text(
                      CurrencyFormatter.format(amount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: ColorPalette.purple,
                      ),
                    ),
                ],
              ),
              if (metrics.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (var i = 0; i < metrics.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      _MetricChip(metric: metrics[i]),
                    ],
                    const Spacer(),
                    Text(
                      '${DateFormatter.shortDate(date)} · $timeLabel',
                      style: appText.caption,
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${DateFormatter.shortDate(date)} · $timeLabel',
                    style: const TextStyle(
                      fontSize: 12,
                      color: ColorPalette.labelSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.metric});

  final RegisterEntryMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: metric.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${metric.label} ${metric.value}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: metric.color,
        ),
      ),
    );
  }
}
