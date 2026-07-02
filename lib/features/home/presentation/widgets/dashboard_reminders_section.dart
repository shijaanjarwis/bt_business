import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/reminders/reminder_models.dart';
import '../../../../core/reminders/reminder_navigation.dart';
import '../../../../core/reminders/reminder_service.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';

/// Today + overdue reminders — tap opens transaction detail.
class DashboardRemindersSection extends StatelessWidget {
  const DashboardRemindersSection({
    super.key,
    required this.reminders,
  });

  final List<ReminderEntry> reminders;

  @override
  Widget build(BuildContext context) {
    if (reminders.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BilingualLabel(
          english: "Today's Reminders",
          hindi: 'Aaj Ke Reminder',
          compact: true,
        ),
        const SizedBox(height: AppSpacing.md),
        ...reminders.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _ReminderCard(entry: entry),
          ),
        ),
      ],
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.entry});

  final ReminderEntry entry;

  @override
  Widget build(BuildContext context) {
    final dueLabel = ReminderService.dueLabel(entry.reminderDate);
    final isOverdue = entry.isOverdue;

    return Material(
      color: isOverdue ? ColorPalette.warningSurface : ColorPalette.cardSurface,
      borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openReminderEntryDetail(context, entry),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: isOverdue ? ColorPalette.warningBorder : ColorPalette.border,
            ),
            borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          ),
          child: Row(
            children: [
              Icon(
                entry.direction == ReminderDirection.receive
                    ? Icons.call_received_rounded
                    : Icons.call_made_rounded,
                color: entry.direction == ReminderDirection.receive
                    ? ColorPalette.accentGreen
                    : ColorPalette.accentOrange,
                size: AppDimensions.iconSizeSm,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.direction.englishLabel} ${CurrencyFormatter.format(entry.amount)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: ColorPalette.labelPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.partyName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ColorPalette.labelSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    dueLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isOverdue
                          ? ColorPalette.warningText
                          : ColorPalette.purple,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.format(entry.amount),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: ColorPalette.labelSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
