import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../domain/entities/party_history_entry.dart';

/// Opens the existing edit screen for a party history row.
void openPartyHistoryEntry(
  BuildContext context, {
  required PartyHistoryEntry entry,
  required String partyId,
}) {
  switch (entry.kind) {
    case PartyHistoryKind.sale:
      context.push(RouteNames.salesEditPath(entry.id));
    case PartyHistoryKind.purchase:
      context.push(RouteNames.purchasesEditPath(entry.id));
    case PartyHistoryKind.received:
    case PartyHistoryKind.paid:
      context.push(RouteNames.paymentsEditPath(entry.id));
    case PartyHistoryKind.opening:
      context.push(RouteNames.ledgerPartyEditPath(partyId));
  }
}
