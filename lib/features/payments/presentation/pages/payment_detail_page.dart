import 'package:bt_business/core/errors/user_error_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/reminders/reminder_service.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../features/ledger/presentation/utils/party_ledger_ui_helpers.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../../shared/widgets/register/register_detail_scaffold.dart';
import '../../../../shared/utils/register_party_label.dart';
import '../../../sales/presentation/providers/sale_providers.dart';
import '../providers/payment_providers.dart';

/// Read-only payment / receive register entry.
class PaymentDetailPage extends ConsumerWidget {
  const PaymentDetailPage({
    super.key,
    required this.paymentId,
  });

  final String paymentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentAsync = ref.watch(paymentDetailProvider(paymentId));
    final cashCustomerId = ref.watch(cashCustomerPartyIdProvider).valueOrNull;

    return paymentAsync.when(
      loading: () => const Scaffold(body: AppLoadingView()),
      error: (error, _) => Scaffold(
        body: AppErrorView(
          title: 'Entry load nahi ho payi',
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
              message: 'Yeh entry nahi mili.',
              actionEnglish: 'Back',
              actionHindi: 'Wapas',
              onAction: () => context.pop(),
            ),
          );
        }

        final partyTitle = RegisterPartyLabel.paymentTitle(
          partyId: entry.partyId,
          partyName: entry.partyName,
          cashCustomerPartyId: cashCustomerId,
        );
        final timeLabel = DateFormat('h:mm a').format(entry.createdAt);
        final typeEnglish = entry.isReceived ? 'Receive' : 'Payment';
        final typeHindi = entry.isReceived ? 'Paisa Mila' : 'Paisa Diya';
        final balanceText = entry.balanceAfterPayment == null
            ? '—'
            : PartyLedgerUiHelpers.runningBalanceLabel(entry.balanceAfterPayment!);
        final balanceColor = entry.balanceAfterPayment == null
            ? ColorPalette.labelSecondary
            : PartyLedgerUiHelpers.runningBalanceColor(entry.balanceAfterPayment!);

        return RegisterDetailScaffold(
          englishTitle: '$typeEnglish Details',
          hindiTitle: '$typeHindi Detail',
          onEdit: () => context.push(RouteNames.paymentsEditPath(entry.id)),
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
              english: 'Amount',
              hindi: 'Rashi',
              value: CurrencyFormatter.format(entry.amount),
              valueColor: ColorPalette.purple,
            ),
            RegisterDetailRow(
              english: 'Payment Mode',
              hindi: 'Payment Mode',
              value: entry.paymentModeLabel,
            ),
            RegisterDetailRow(
              english: 'Balance After Payment',
              hindi: 'Baad Ka Hisaab',
              value: balanceText,
              valueColor: balanceColor,
            ),
            if (entry.partyPhone.isNotEmpty)
              RegisterDetailRow(
                english: 'Phone',
                hindi: 'Mobile',
                value: entry.partyPhone,
              ),
            if (entry.note != null && entry.note!.trim().isNotEmpty)
              RegisterDetailRow(
                english: 'Notes',
                hindi: 'Note',
                value: entry.note!.trim(),
              ),
            if (entry.reminderDate != null)
              RegisterDetailRow(
                english: 'Next Reminder',
                hindi: 'Agla Reminder',
                value: ReminderService.dueLabel(entry.reminderDate!),
              ),
          ],
        );
      },
    );
  }
}
