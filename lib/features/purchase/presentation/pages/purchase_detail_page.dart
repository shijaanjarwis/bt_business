import 'package:bt_business/core/errors/user_error_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/reminders/reminder_service.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../../shared/widgets/inputs/payment_breakdown_fields.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';
import '../../../../shared/widgets/register/register_detail_scaffold.dart';
import '../../../../shared/widgets/register/register_party_link.dart';
import '../../../../shared/utils/register_party_label.dart';
import '../../../ledger/presentation/providers/party_providers.dart';
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

        final livePartyName =
            ref.watch(partyDetailProvider(invoice.partyId)).valueOrNull?.name ??
                invoice.partyName;
        final partyTitle = RegisterPartyLabel.purchaseTitle(
          partyId: invoice.partyId,
          partyName: livePartyName,
          cashCustomerPartyId: cashCustomerId,
        );
        final timeLabel = DateFormat('h:mm a').format(invoice.createdAt);
        final notes = invoice.notes?.trim();

        return RegisterDetailScaffold(
          englishTitle: 'Purchase Details',
          hindiTitle: 'Kharid Detail',
          onEdit: () => context.push(RouteNames.purchasesEditPath(invoice.id)),
          children: [
            RegisterPartyHeaderLink(
              partyId: invoice.partyId,
              partyName: livePartyName,
              cashCustomerPartyId: cashCustomerId,
              displayName: partyTitle,
            ),
            const SizedBox(height: 4),
            Text(
              '${DateFormatter.displayDate(invoice.date)} · $timeLabel',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ColorPalette.labelSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const BilingualLabel(
              english: 'Items',
              hindi: 'Maal',
              compact: true,
            ),
            const SizedBox(height: AppSpacing.sm),
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
            const SizedBox(height: AppSpacing.sm),
            PaymentBreakdownDisplay(
              breakdown: invoice.paymentBreakdown,
              grandTotal: invoice.grandTotal,
              creditEnglish: 'Credit',
              creditHindi: 'Udhaar',
            ),
            if (invoice.reminderDate != null) ...[
              const SizedBox(height: AppSpacing.md),
              RegisterDetailRow(
                english: 'Reminder',
                hindi: 'Reminder',
                value: ReminderService.dueLabel(invoice.reminderDate!),
              ),
            ],
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                notes,
                style: const TextStyle(
                  fontSize: 14,
                  color: ColorPalette.labelSecondary,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
