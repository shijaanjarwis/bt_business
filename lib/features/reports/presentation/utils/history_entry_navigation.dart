import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/accounting/transaction_types.dart';
import '../../../../core/router/route_names.dart';
import '../../data/datasources/transaction_history_local_datasource.dart';
import '../../domain/history_models.dart';

/// Opens the existing edit screen for a register history row when supported.
void openHistoryEntry(BuildContext context, TransactionHistoryEntry entry) {
  switch (entry.type) {
    case TransactionTypes.sale:
      context.push(RouteNames.salesEditPath(entry.id));
    case TransactionTypes.purchase:
      context.push(RouteNames.purchasesEditPath(entry.id));
    case TransactionTypes.paymentReceived:
    case TransactionTypes.paymentPaid:
    case TransactionTypes.expense:
      context.push(RouteNames.paymentsEditPath(entry.id));
    case HistoryEntryTypes.partyCreated:
    case HistoryEntryTypes.partyUpdated:
      context.push(RouteNames.ledgerPartyEditPath(entry.id));
    default:
      break;
  }
}
