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
import '../../../../shared/widgets/labels/bilingual_label.dart';
import '../../../../shared/widgets/register/register_detail_scaffold.dart';
import '../../../../shared/utils/register_party_label.dart';
import '../../../sales/presentation/providers/sale_providers.dart';
import '../providers/purchase_providers.dart';

/// Read-only purchase register entry.
class PurchaseDetailPage extends ConsumerWidget {
  const PurchaseDetailPage({
    super.key,
    required this.purchaseId,
  });

  final String purchaseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseAsync = ref.watch(purchaseDetailProvider(purchaseId));
    final cashCustomerId = ref.watch(cashCustomerPartyIdProvider).valueOrNull;

    return purchaseAsync.when(
      loading: () => const Scaffold(body: AppLoadingView()),
      error: (error, _) => Scaffold(
        body: AppErrorView(
          title: 'Purchase load nahi ho payi',
          message: UserErrorMessages.from(error),
          actionEnglish: 'Back',
          actionHindi: 'Wapas',
          onAction: () => context.pop(),
        ),
      ),
      data: (invoice) {
        if (invoice == null) {
          return Scaffold(
            body: AppErrorView(
              title: 'Not found',
              message: 'Yeh kharid nahi mili.',
              actionEnglish: 'Back',
              actionHindi: 'Wapas',
              onAction: () => context.pop(),
            ),
          );
        }

        final partyTitle = RegisterPartyLabel.purchaseTitle(
          partyId: invoice.partyId,
          partyName: invoice.partyName,
          cashCustomerPartyId: cashCustomerId,
        );
        final timeLabel = DateFormat('h:mm a').format(invoice.createdAt);
        final paymentMode =
            invoice.paymentMode == PaymentMode.credit ? 'Credit' : 'Cash';

        return RegisterDetailScaffold(
          englishTitle: 'Purchase Details',
          hindiTitle: 'Kharid Detail',
          onEdit: () => context.push(RouteNames.purchasesEditPath(invoice.id)),
          children: [
            RegisterDetailRow(
              english: 'Party',
              hindi: 'Party',
              value: partyTitle,
            ),
            RegisterDetailRow(
              english: 'Date',
              hindi: 'Date',
              value: '${DateFormatter.displayDate(invoice.date)} · $timeLabel',
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
            ...invoice.lines.map(
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
              value: CurrencyFormatter.format(invoice.grandTotal),
              valueColor: ColorPalette.purple,
            ),
            RegisterDetailRow(
              english: 'Paid',
              hindi: 'Diya',
              value: CurrencyFormatter.format(invoice.paidAmount),
              valueColor: ColorPalette.accentGreen,
            ),
            RegisterDetailRow(
              english: 'Remaining',
              hindi: 'Baaki',
              value: CurrencyFormatter.format(invoice.dueAmount),
              valueColor: invoice.dueAmount > 0
                  ? ColorPalette.accentOrange
                  : ColorPalette.labelSecondary,
            ),
            if (invoice.reminderDate != null)
              RegisterDetailRow(
                english: 'Next Reminder',
                hindi: 'Agla Reminder',
                value: ReminderService.dueLabel(invoice.reminderDate!),
              ),
            if (invoice.notes != null && invoice.notes!.trim().isNotEmpty)
              RegisterDetailRow(
                english: 'Notes',
                hindi: 'Note',
                value: invoice.notes!.trim(),
              ),
          ],
        );
      },
    );
  }
}
