import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../accounting/transaction_types.dart';
import '../router/route_names.dart';
import 'reminder_models.dart';

/// Opens the read-only detail screen for a reminder row.
void openReminderEntryDetail(BuildContext context, ReminderEntry entry) {
  switch (entry.transactionType) {
    case TransactionTypes.sale:
      context.push(RouteNames.salesDetailPath(entry.transactionId));
    case TransactionTypes.purchase:
      context.push(RouteNames.purchasesDetailPath(entry.transactionId));
    case TransactionTypes.paymentReceived:
    case TransactionTypes.paymentPaid:
      context.push(RouteNames.paymentsDetailPath(entry.transactionId));
    default:
      break;
  }
}

/// Parses notification payload `type:transactionId` into a detail route.
String? reminderDetailPathFromPayload(String? payload) {
  if (payload == null || payload.isEmpty) return null;

  final parts = payload.split(':');
  if (parts.length != 2) return null;

  final type = parts[0];
  final id = parts[1];

  return switch (type) {
    TransactionTypes.sale => RouteNames.salesDetailPath(id),
    TransactionTypes.purchase => RouteNames.purchasesDetailPath(id),
    TransactionTypes.paymentReceived => RouteNames.paymentsDetailPath(id),
    TransactionTypes.paymentPaid => RouteNames.paymentsDetailPath(id),
    _ => null,
  };
}
