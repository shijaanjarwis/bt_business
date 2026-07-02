import 'package:bt_business/core/errors/user_error_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/accounting/payment_modes.dart';
import '../../../../core/reminders/reminder_service.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../../shared/widgets/register/register_detail_scaffold.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';
import '../../../../shared/utils/register_party_label.dart';
import '../providers/sale_providers.dart';

/// Read-only sale register entry — tap from list to view full details.
class SaleDetailPage extends ConsumerWidget {
  const SaleDetailPage({
    super.key,
    required this.saleId,
  });

  final String saleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saleAsync = ref.watch(saleDetailProvider(saleId));
    final cashCustomerId = ref.watch(cashCustomerPartyIdProvider).valueOrNull;

    return saleAsync.when(
      loading: () => const Scaffold(body: AppLoadingView()),
      error: (error, _) => Scaffold(
        body: AppErrorView(
          title: 'Sale load nahi ho payi',
          message: UserErrorMessages.from(error),
          actionEnglish: 'Back',
          actionHindi: 'Wapas',
          onAction: () => context.pop(),
        ),
      ),
      data: (entry) {
        if (entry == null) {
          return Scaffold(
            body: AppErrorView(
              title: 'Not found',
              message: 'Yeh bikri nahi mili.',
              actionEnglish: 'Back',
              actionHindi: 'Wapas',
              onAction: () => context.pop(),
            ),
          );
        }

        final partyTitle = RegisterPartyLabel.saleTitle(
          partyId: entry.partyId,
          partyName: entry.partyName,
          cashCustomerPartyId: cashCustomerId,
        );
        final timeLabel = DateFormat('h:mm a').format(entry.createdAt);
        final paymentMode = entry.paymentMode == PaymentMode.credit ? 'Credit' : 'Cash';

        return RegisterDetailScaffold(
          englishTitle: 'Sale Details',
          hindiTitle: 'Bikri Detail',
          onEdit: () => context.push(RouteNames.salesEditPath(entry.id)),
          children: [
            RegisterDetailRow(
              english: 'Party',
              hindi: 'Party',
              value: partyTitle,
            ),
            RegisterDetailRow(
              english: 'Date',
              hindi: 'Date',
              value: '${DateFormatter.displayDate(entry.date)} · $timeLabel',
            ),
            RegisterDetailRow(
              english: 'Payment Mode',
              hindi: 'Payment Mode',
              value: paymentMode,
            ),
            const Divider(),
            const BilingualLabel(
              english: 'Items',
              hindi: 'Maal',
              compact: true,
            ),
            const SizedBox(height: 8),
            ...entry.lines.map(
              (line) => RegisterLineItemTile(
                itemName: line.itemName,
                qty: line.qty,
                rate: line.rate,
                amount: line.lineTotal,
              ),
            ),
            RegisterDetailRow(
              english: 'Total',
              hindi: 'Total',
              value: CurrencyFormatter.format(entry.grandTotal),
              valueColor: ColorPalette.purple,
            ),
            RegisterDetailRow(
              english: 'Received',
              hindi: 'Mila',
              value: CurrencyFormatter.format(entry.paidAmount),
              valueColor: ColorPalette.accentGreen,
            ),
            RegisterDetailRow(
              english: 'Remaining',
              hindi: 'Baaki',
              value: CurrencyFormatter.format(entry.dueAmount),
              valueColor: entry.dueAmount > 0
                  ? ColorPalette.accentOrange
                  : ColorPalette.labelSecondary,
            ),
            if (entry.reminderDate != null)
              RegisterDetailRow(
                english: 'Next Reminder',
                hindi: 'Agla Reminder',
                value: ReminderService.dueLabel(entry.reminderDate!),
              ),
            if (entry.notes != null && entry.notes!.trim().isNotEmpty)
              RegisterDetailRow(
                english: 'Notes',
                hindi: 'Note',
                value: entry.notes!.trim(),
              ),
          ],
        );
      },
    );
  }
}
