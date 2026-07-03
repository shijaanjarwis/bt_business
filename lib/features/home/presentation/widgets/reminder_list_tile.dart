import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/accounting/transaction_types.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/reminders/reminder_models.dart';
import '../../../../core/reminders/reminder_navigation.dart';
import '../../../../core/reminders/reminder_service.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';

/// Register-style reminder row with quick actions.
class ReminderListTile extends StatelessWidget {
  const ReminderListTile({
    super.key,
    required this.entry,
    this.lastActivity,
    this.showLastActivity = false,
  });

  final ReminderEntry entry;
  final DateTime? lastActivity;
  final bool showLastActivity;

  bool get _isReceive => entry.direction == ReminderDirection.receive;

  @override
  Widget build(BuildContext context) {
    final status = ReminderService.dueLabel(entry.reminderDate);
    final isOverdue = entry.isOverdue;

    return Material(
      color: isOverdue ? ColorPalette.warningSurface : ColorPalette.cardSurface,
      borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openReminderEntryDetail(context, entry),
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
                          entry.partyName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: ColorPalette.labelPrimary,
                          ),
                        ),
                        if (entry.partyPhone.trim().isNotEmpty) ...[
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
                                entry.partyPhone.trim(),
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
                        CurrencyFormatter.format(entry.amount),
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
                'Due: ${DateFormatter.shortDate(entry.reminderDate)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.labelSecondary,
                ),
              ),
              if (showLastActivity && lastActivity != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Last: ${DateFormatter.shortDate(lastActivity!)} · ${DateFormat('h:mm a').format(lastActivity!)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: ColorPalette.labelTertiary,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ActionChip(
                    label: 'Party',
                    onTap: () => context.push(
                      RouteNames.ledgerPartyDetailPath(entry.partyId),
                    ),
                  ),
                  _ActionChip(
                    label: 'Edit',
                    onTap: () => _openEdit(context),
                  ),
                  _ActionChip(
                    label: _isReceive ? 'Receive' : 'Pay',
                    highlighted: true,
                    onTap: () => _recordPayment(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEdit(BuildContext context) {
    switch (entry.transactionType) {
      case TransactionTypes.sale:
        context.push(RouteNames.salesEditPath(entry.transactionId));
      case TransactionTypes.purchase:
        context.push(RouteNames.purchasesEditPath(entry.transactionId));
      case TransactionTypes.paymentReceived:
      case TransactionTypes.paymentPaid:
        context.push(RouteNames.paymentsEditPath(entry.transactionId));
      default:
        break;
    }
  }

  void _recordPayment(BuildContext context) {
    final path = _isReceive
        ? '${RouteNames.paymentsReceived}?partyId=${entry.partyId}'
        : '${RouteNames.paymentsPaid}?partyId=${entry.partyId}';
    context.push(path);
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted
          ? ColorPalette.purple.withValues(alpha: 0.12)
          : ColorPalette.background,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: highlighted ? ColorPalette.purple : ColorPalette.labelPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
