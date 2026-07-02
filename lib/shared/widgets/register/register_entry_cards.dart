import 'package:flutter/material.dart';

import '../../../core/theme/color_palette.dart';
import '../../../core/theme/transaction_badge_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../features/ledger/presentation/utils/party_ledger_ui_helpers.dart';
import '../../../features/payments/domain/entities/payment_register_entry.dart';
import '../../../features/purchase/domain/entities/purchase_invoice.dart';
import '../../../features/purchase/presentation/utils/purchase_ui_helpers.dart';
import '../../../features/reports/data/datasources/transaction_history_local_datasource.dart';
import '../../../features/reports/presentation/utils/history_ui_helpers.dart';
import '../../../features/sales/domain/entities/sale_entry.dart';
import '../../../features/sales/presentation/utils/sale_ui_helpers.dart';
import '../../../shared/utils/register_party_label.dart';
import 'register_entry_card.dart';

/// Builds shared register cards from each register entity type.
abstract final class RegisterEntryCards {
  static RegisterEntryCard sale({
    required SaleEntry entry,
    required VoidCallback onTap,
    String? cashCustomerPartyId,
  }) {
    return RegisterEntryCard(
      partyTitle: SaleUiHelpers.partyLabel(
        partyId: entry.partyId,
        partyName: entry.partyName,
        cashCustomerPartyId: cashCustomerPartyId,
      ),
      amount: entry.grandTotal,
      date: entry.date,
      createdAt: entry.createdAt,
      onTap: onTap,
      metrics: [
        RegisterEntryMetric(
          label: 'Received',
          value: CurrencyFormatter.format(entry.paidAmount),
          color: ColorPalette.accentGreen,
        ),
        RegisterEntryMetric(
          label: 'Remaining',
          value: CurrencyFormatter.format(entry.dueAmount),
          color: entry.dueAmount > 0
              ? ColorPalette.accentOrange
              : ColorPalette.labelSecondary,
        ),
      ],
    );
  }

  static RegisterEntryCard purchase({
    required PurchaseInvoice invoice,
    required VoidCallback onTap,
    String? cashCustomerPartyId,
  }) {
    return RegisterEntryCard(
      partyTitle: PurchaseUiHelpers.partyLabel(
        partyId: invoice.partyId,
        partyName: invoice.partyName,
        defaultPartyId: cashCustomerPartyId,
      ),
      amount: invoice.grandTotal,
      date: invoice.date,
      createdAt: invoice.createdAt,
      onTap: onTap,
      metrics: [
        RegisterEntryMetric(
          label: 'Paid',
          value: CurrencyFormatter.format(invoice.paidAmount),
          color: ColorPalette.accentGreen,
        ),
        RegisterEntryMetric(
          label: 'Remaining',
          value: CurrencyFormatter.format(invoice.dueAmount),
          color: invoice.dueAmount > 0
              ? ColorPalette.accentOrange
              : ColorPalette.labelSecondary,
        ),
      ],
    );
  }

  static RegisterEntryCard payment({
    required PaymentRegisterEntry entry,
    required VoidCallback onTap,
    String? cashCustomerPartyId,
  }) {
    final badgeKind = entry.isReceived
        ? TransactionBadgeKind.receive
        : TransactionBadgeKind.payment;
    final balanceText = entry.balanceAfterPayment == null
        ? null
        : PartyLedgerUiHelpers.runningBalanceLabel(entry.balanceAfterPayment!);

    return RegisterEntryCard(
      partyTitle: RegisterPartyLabel.paymentTitle(
        partyId: entry.partyId,
        partyName: entry.partyName,
        cashCustomerPartyId: cashCustomerPartyId,
      ),
      amount: entry.amount,
      date: entry.date,
      createdAt: entry.createdAt,
      onTap: onTap,
      badgeKind: badgeKind,
      subtitle: [
        entry.paymentModeLabel,
        if (balanceText != null) 'Balance $balanceText',
      ].join(' · '),
    );
  }

  static RegisterEntryCard history({
    required TransactionHistoryEntry entry,
    required VoidCallback onTap,
  }) {
    final badgeKind = TransactionBadgeKind.fromTransactionType(entry.type);
    final showAmount = HistoryUiHelpers.showAmountFor(entry);

    return RegisterEntryCard(
      partyTitle: HistoryUiHelpers.displayPartyTitle(entry),
      amount: entry.amount,
      date: entry.date,
      createdAt: entry.createdAt,
      onTap: onTap,
      badgeKind: badgeKind,
      showAmount: showAmount,
    );
  }
}
