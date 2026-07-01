import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../domain/entities/party_history_entry.dart';

/// Opens the existing edit/create screen for a party history row.
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
      context.push('${RouteNames.paymentsReceived}?partyId=$partyId');
    case PartyHistoryKind.paid:
      context.push('${RouteNames.paymentsPaid}?partyId=$partyId');
    case PartyHistoryKind.opening:
      context.push(RouteNames.ledgerPartyEditPath(partyId));
  }
}
