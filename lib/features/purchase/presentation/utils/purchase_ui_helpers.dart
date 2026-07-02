import '../../../../shared/utils/register_party_label.dart';
import '../../domain/entities/purchase_invoice.dart';
import '../models/purchase_register_filter.dart';

/// Presentation helpers for purchase screens.
abstract final class PurchaseUiHelpers {
  static bool isDefaultCashParty({
    required String partyId,
    required String partyName,
    String? defaultPartyId,
  }) {
    return RegisterPartyLabel.isCashCustomerParty(
      partyId: partyId,
      partyName: partyName,
      cashCustomerPartyId: defaultPartyId,
    );
  }

  static String partyLabel({
    required String partyId,
    required String partyName,
    String? defaultPartyId,
  }) {
    return RegisterPartyLabel.purchaseTitle(
      partyId: partyId,
      partyName: partyName,
      cashCustomerPartyId: defaultPartyId,
    );
  }

  static bool matchesRegisterFilter(
    PurchaseInvoice invoice,
    PurchaseRegisterFilter filter,
  ) {
    switch (filter) {
      case PurchaseRegisterFilter.all:
        return true;
      case PurchaseRegisterFilter.todayPaid:
        final today = DateTime.now();
        final isToday = invoice.date.year == today.year &&
            invoice.date.month == today.month &&
            invoice.date.day == today.day;
        return isToday && invoice.paidAmount > 0;
      case PurchaseRegisterFilter.hasBalance:
        return invoice.dueAmount > 0;
    }
  }
}
