import '../../../../data/local/database/seeders/cash_customer_seeder.dart';
import '../../domain/entities/sale_entry.dart';
import '../models/sale_register_filter.dart';

/// Presentation helpers for sale screens — no business-rule changes.
abstract final class SaleUiHelpers {
  static bool isCashCustomerParty({
    required String partyId,
    required String partyName,
    String? cashCustomerPartyId,
  }) {
    if (cashCustomerPartyId != null && partyId == cashCustomerPartyId) {
      return true;
    }
    return partyName == CashCustomerSeeder.displayName;
  }

  static String partyLabel({
    required String partyId,
    required String partyName,
    String? cashCustomerPartyId,
  }) {
    if (isCashCustomerParty(
      partyId: partyId,
      partyName: partyName,
      cashCustomerPartyId: cashCustomerPartyId,
    )) {
      return 'Cash Bikri';
    }
    return partyName;
  }

  static bool matchesRegisterFilter(SaleEntry entry, SaleRegisterFilter filter) {
    switch (filter) {
      case SaleRegisterFilter.all:
        return true;
      case SaleRegisterFilter.todayCashReceived:
        final today = DateTime.now();
        final isToday = entry.date.year == today.year &&
            entry.date.month == today.month &&
            entry.date.day == today.day;
        return isToday && entry.paidAmount > 0;
      case SaleRegisterFilter.hasBalance:
        return entry.dueAmount > 0;
    }
  }
}
