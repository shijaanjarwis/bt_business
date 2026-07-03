import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/accounting/transaction_types.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/transaction_badge_theme.dart';
import '../../../../shared/widgets/register/register_entry_card.dart';
import '../../../../shared/widgets/register/register_entry_cards.dart';
import '../../../purchase/domain/entities/purchase_invoice.dart';
import '../../../sales/domain/entities/sale_entry.dart';
import '../../domain/entities/dashboard_summary_entry.dart';
import '../utils/dashboard_summary_navigation.dart';

/// List tile for dashboard summary detail screens.
abstract final class DashboardSummaryListTiles {
  static Widget sale({
    required SaleEntry entry,
    required BuildContext context,
    String? cashCustomerPartyId,
  }) {
    return RegisterEntryCards.sale(
      entry: entry,
      cashCustomerPartyId: cashCustomerPartyId,
      onTap: () => context.push(RouteNames.salesDetailPath(entry.id)),
    );
  }

  static Widget purchase({
    required PurchaseInvoice invoice,
    required BuildContext context,
    String? cashCustomerPartyId,
  }) {
    return RegisterEntryCards.purchase(
      invoice: invoice,
      cashCustomerPartyId: cashCustomerPartyId,
      onTap: () => context.push(RouteNames.purchasesDetailPath(invoice.id)),
    );
  }

  static Widget entry({
    required DashboardSummaryEntry entry,
    required BuildContext context,
  }) {
    final badgeKind = switch (entry.transactionType) {
      TransactionTypes.paymentReceived => TransactionBadgeKind.receive,
      TransactionTypes.paymentPaid => TransactionBadgeKind.payment,
      TransactionTypes.expense => TransactionBadgeKind.expense,
      TransactionTypes.sale => TransactionBadgeKind.sale,
      TransactionTypes.purchase => TransactionBadgeKind.purchase,
      _ => null,
    };

    return RegisterEntryCard(
      partyTitle: entry.title,
      amount: entry.amount,
      date: entry.date,
      createdAt: entry.createdAt,
      onTap: () => DashboardSummaryNavigation.openEntry(context, entry),
      badgeKind: badgeKind,
      subtitle: entry.subtitle,
    );
  }
}
