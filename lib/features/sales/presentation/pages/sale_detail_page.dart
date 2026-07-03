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
import '../../../../shared/widgets/register/register_detail_scaffold.dart';
import '../../../../shared/widgets/register/register_party_link.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';
import '../../../../shared/utils/register_party_label.dart';
import '../../../ledger/presentation/providers/party_providers.dart';
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

        final livePartyName =
            ref.watch(partyDetailProvider(entry.partyId)).valueOrNull?.name ??
                entry.partyName;
        final partyTitle = RegisterPartyLabel.saleTitle(
          partyId: entry.partyId,
          partyName: livePartyName,
          cashCustomerPartyId: cashCustomerId,
        );
        final timeLabel = DateFormat('h:mm a').format(entry.createdAt);
        final notes = entry.notes?.trim();

        return RegisterDetailScaffold(
          englishTitle: 'Sale Details',
          hindiTitle: 'Bikri Detail',
          onEdit: () => context.push(RouteNames.salesEditPath(entry.id)),
          children: [
            RegisterPartyHeaderLink(
              partyId: entry.partyId,
              partyName: livePartyName,
              cashCustomerPartyId: cashCustomerId,
              displayName: partyTitle,
            ),
            const SizedBox(height: 4),
            Text(
              '${DateFormatter.displayDate(entry.date)} · $timeLabel',
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
            const SizedBox(height: AppSpacing.sm),
            PaymentBreakdownDisplay(
              breakdown: entry.paymentBreakdown,
              grandTotal: entry.grandTotal,
              creditEnglish: 'Credit',
              creditHindi: 'Udhaar',
            ),
            if (entry.reminderDate != null) ...[
              const SizedBox(height: AppSpacing.md),
              RegisterDetailRow(
                english: 'Reminder',
                hindi: 'Reminder',
                value: ReminderService.dueLabel(entry.reminderDate!),
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
