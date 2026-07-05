import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/accounting/transaction_types.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/reminders/reminder_models.dart';
import '../../../../core/reminders/reminder_navigation.dart';
import '../../../../core/reminders/reminder_service.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';

/// One pending transaction row on the party detail screen.
class PartyPendingEntryTile extends StatelessWidget {
  const PartyPendingEntryTile({
    super.key,
    required this.entry,
  });

  final ReminderEntry entry;

  bool get _isReceive => entry.direction == ReminderDirection.receive;

  @override
  Widget build(BuildContext context) {
    final status = ReminderService.dueLabel(entry.reminderDate);
    final isOverdue = entry.isOverdue;
    final entryDate = entry.transactionDate ?? entry.reminderDate;
    final notes = entry.notes.trim();

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormatter.shortDate(entryDate),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: ColorPalette.labelPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Reminder: ${DateFormatter.shortDate(entry.reminderDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isOverdue
                                ? ColorPalette.warningText
                                : ColorPalette.labelSecondary,
                          ),
                        ),
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
                'Baaki: ${CurrencyFormatter.format(entry.dueAmount)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.labelSecondary,
                ),
              ),
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  notes,
                  style: const TextStyle(
                    fontSize: 13,
                    color: ColorPalette.labelSecondary,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
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
