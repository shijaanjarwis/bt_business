import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/accounting/transaction_types.dart';
import '../../../../core/router/route_names.dart';
import '../../domain/entities/dashboard_summary_entry.dart';

/// Opens the read-only detail screen for a dashboard summary row.
abstract final class DashboardSummaryNavigation {
  static void openEntry(BuildContext context, DashboardSummaryEntry entry) {
    switch (entry.transactionType) {
      case TransactionTypes.sale:
        context.push(RouteNames.salesDetailPath(entry.id));
      case TransactionTypes.purchase:
        context.push(RouteNames.purchasesDetailPath(entry.id));
      case TransactionTypes.paymentReceived:
      case TransactionTypes.paymentPaid:
      case TransactionTypes.expense:
        context.push(RouteNames.paymentsDetailPath(entry.id));
      default:
        break;
    }
  }
}
