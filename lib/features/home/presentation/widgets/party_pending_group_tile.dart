import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/reminders/reminder_models.dart';
import '../../../../core/reminders/reminder_service.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';

/// Grouped party card for Pending Receivable / Pending Payable lists.
class PartyPendingGroupTile extends StatelessWidget {
  const PartyPendingGroupTile({
    super.key,
    required this.group,
    required this.kindSlug,
  });

  final PartyPendingGroup group;
  final String kindSlug;

  bool get _isReceive => group.direction == ReminderDirection.receive;

  @override
  Widget build(BuildContext context) {
    final status = ReminderService.dueLabel(group.oldestDueDate);
    final isOverdue = group.isOverdue;

    return Material(
      color: isOverdue ? ColorPalette.warningSurface : ColorPalette.cardSurface,
      borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          RouteNames.partyPendingDetailPath(kindSlug, group.partyId),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isOverdue ? ColorPalette.warningBorder : ColorPalette.border,
            ),
            borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _isReceive
                        ? Icons.call_received_rounded
                        : Icons.call_made_rounded,
                    color: _isReceive
                        ? ColorPalette.accentGreen
                        : ColorPalette.accentOrange,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.partyName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: ColorPalette.labelPrimary,
                          ),
                        ),
                        if (group.partyPhone.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone_outlined,
                                size: 14,
                                color: ColorPalette.labelSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                group.partyPhone.trim(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: ColorPalette.labelSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.format(group.totalPendingAmount),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: ColorPalette.labelPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isOverdue
                              ? ColorPalette.warningText
                              : ColorPalette.purple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${group.entryCount} pending bills · Oldest due: ${DateFormatter.shortDate(group.oldestDueDate)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.labelSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
