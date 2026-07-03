import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/reminders/reminder_list_kind.dart';
import '../../../../core/reminders/reminder_models.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';

/// Reminder summary cards — receivable/payable buckets for the dashboard.
class DashboardReminderSummarySection extends StatelessWidget {
  const DashboardReminderSummarySection({
    super.key,
    required this.summary,
  });

  final ReminderDashboardSummary summary;

  bool get _hasAny =>
      summary.receiveToday > 0 ||
      summary.payToday > 0 ||
      summary.pendingReceivable > 0 ||
      summary.pendingPayable > 0 ||
      summary.tomorrowReceive > 0 ||
      summary.tomorrowPay > 0 ||
      summary.next7DaysReceive > 0 ||
      summary.next7DaysPay > 0 ||
      summary.overdueReceive > 0 ||
      summary.overduePay > 0;

  @override
  Widget build(BuildContext context) {
    if (!_hasAny) return const SizedBox.shrink();

    final cards = <_ReminderMetric>[
      _ReminderMetric(
        english: 'Receive Today',
        hindi: 'Aaj Lena Hai',
        amount: summary.receiveToday,
        icon: Icons.call_received_rounded,
        color: ColorPalette.accentGreen,
        listKind: ReminderListKind.receiveToday,
      ),
      _ReminderMetric(
        english: 'Pay Today',
        hindi: 'Aaj Dena Hai',
        amount: summary.payToday,
        icon: Icons.call_made_rounded,
        color: ColorPalette.accentOrange,
        listKind: ReminderListKind.payToday,
      ),
      _ReminderMetric(
        english: 'Pending Receivable',
        hindi: 'Lena Hai',
        amount: summary.pendingReceivable,
        icon: Icons.schedule_rounded,
        color: ColorPalette.purple,
        listKind: ReminderListKind.pendingReceivable,
      ),
      _ReminderMetric(
        english: 'Pending Payable',
        hindi: 'Dena Hai',
        amount: summary.pendingPayable,
        icon: Icons.schedule_send_rounded,
        color: ColorPalette.accentOrange,
        listKind: ReminderListKind.pendingPayable,
      ),
      _ReminderMetric(
        english: 'Tomorrow',
        hindi: 'Kal',
        amount: summary.tomorrowReceive + summary.tomorrowPay,
        icon: Icons.today_outlined,
        color: ColorPalette.labelSecondary,
        subtitle: _pairSubtitle(summary.tomorrowReceive, summary.tomorrowPay),
        listKind: ReminderListKind.tomorrow,
      ),
      _ReminderMetric(
        english: 'Next 7 Days',
        hindi: 'Agle 7 Din',
        amount: summary.next7DaysReceive + summary.next7DaysPay,
        icon: Icons.date_range_outlined,
        color: ColorPalette.labelSecondary,
        subtitle: _pairSubtitle(summary.next7DaysReceive, summary.next7DaysPay),
        listKind: ReminderListKind.next7Days,
      ),
      _ReminderMetric(
        english: 'Overdue',
        hindi: 'Late Ho Gaya',
        amount: summary.overdueReceive + summary.overduePay,
        icon: Icons.warning_amber_rounded,
        color: ColorPalette.warningText,
        subtitle: _pairSubtitle(summary.overdueReceive, summary.overduePay),
        highlight: summary.overdueReceive + summary.overduePay > 0,
        listKind: ReminderListKind.overdue,
      ),
    ].where((card) => card.amount > 0).toList();

    if (cards.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BilingualLabel(
          english: 'Reminder Summary',
          hindi: 'Reminder Hisaab',
          compact: true,
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: cards.map((card) => _SummaryCard(card: card)).toList(),
        ),
      ],
    );
  }

  String? _pairSubtitle(double receive, double pay) {
    if (receive <= 0 && pay <= 0) return null;
    final parts = <String>[];
    if (receive > 0) parts.add('R ${CurrencyFormatter.format(receive)}');
    if (pay > 0) parts.add('P ${CurrencyFormatter.format(pay)}');
    return parts.join(' · ');
  }
}

class _ReminderMetric {
  const _ReminderMetric({
    required this.english,
    required this.hindi,
    required this.amount,
    required this.icon,
    required this.color,
    required this.listKind,
    this.subtitle,
    this.highlight = false,
  });

  final String english;
  final String hindi;
  final double amount;
  final IconData icon;
  final Color color;
  final ReminderListKind listKind;
  final String? subtitle;
  final bool highlight;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.card});

  final _ReminderMetric card;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: card.highlight ? ColorPalette.warningSurface : ColorPalette.cardSurface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          RouteNames.reminderListPath(card.listKind.routeSlug),
        ),
        borderRadius: BorderRadius.circular(18),
        splashColor: ColorPalette.purple.withValues(alpha: 0.12),
        highlightColor: ColorPalette.purple.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(
              color: card.highlight ? ColorPalette.warningBorder : ColorPalette.border,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(card.icon, size: 20, color: card.color),
              const Spacer(),
              BilingualLabel(
                english: card.english,
                hindi: card.hindi,
                compact: true,
              ),
              const SizedBox(height: 8),
              Text(
                CurrencyFormatter.format(card.amount),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ColorPalette.labelPrimary,
                ),
              ),
              if (card.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  card.subtitle!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: ColorPalette.labelSecondary,
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
