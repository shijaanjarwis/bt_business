import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/accounting/transaction_types.dart';
import '../../../../core/router/route_names.dart';
import '../../data/datasources/transaction_history_local_datasource.dart';
import '../../domain/history_models.dart';

/// Opens the read-only detail screen for a register/history row.
void openRegisterEntryDetail(
  BuildContext context,
  TransactionHistoryEntry entry,
) {
  switch (entry.type) {
    case TransactionTypes.sale:
      context.push(RouteNames.salesDetailPath(entry.id));
    case TransactionTypes.purchase:
      context.push(RouteNames.purchasesDetailPath(entry.id));
    case TransactionTypes.paymentReceived:
    case TransactionTypes.paymentPaid:
      context.push(RouteNames.paymentsDetailPath(entry.id));
    case TransactionTypes.expense:
      context.push(RouteNames.paymentsEditPath(entry.id));
    case HistoryEntryTypes.partyCreated:
    case HistoryEntryTypes.partyUpdated:
      context.push(RouteNames.ledgerPartyDetailPath(entry.id));
    default:
      break;
  }
}
