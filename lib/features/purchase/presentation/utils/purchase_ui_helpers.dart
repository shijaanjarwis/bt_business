import '../../../../data/local/database/seeders/cash_customer_seeder.dart';
import '../../domain/entities/purchase_invoice.dart';
import '../models/purchase_register_filter.dart';

/// Presentation helpers for purchase screens — no business-rule changes.
abstract final class PurchaseUiHelpers {
  static bool isDefaultCashParty({
    required String partyId,
    required String partyName,
    String? defaultPartyId,
  }) {
    if (defaultPartyId != null && partyId == defaultPartyId) {
      return true;
    }
    return partyName == CashCustomerSeeder.displayName;
  }

  static String partyLabel({
    required String partyId,
    required String partyName,
    String? defaultPartyId,
  }) {
    if (isDefaultCashParty(
      partyId: partyId,
      partyName: partyName,
      defaultPartyId: defaultPartyId,
    )) {
      return 'Cash Kharid';
    }
    return partyName;
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
