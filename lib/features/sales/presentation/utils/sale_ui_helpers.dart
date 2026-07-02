import '../../../../shared/utils/register_party_label.dart';
import '../../domain/entities/sale_entry.dart';
import '../models/sale_register_filter.dart';

/// Presentation helpers for sale screens.
abstract final class SaleUiHelpers {
  static bool isCashCustomerParty({
    required String partyId,
    required String partyName,
    String? cashCustomerPartyId,
  }) {
    return RegisterPartyLabel.isCashCustomerParty(
      partyId: partyId,
      partyName: partyName,
      cashCustomerPartyId: cashCustomerPartyId,
    );
  }

  static String partyLabel({
    required String partyId,
    required String partyName,
    String? cashCustomerPartyId,
  }) {
    return RegisterPartyLabel.saleTitle(
      partyId: partyId,
      partyName: partyName,
      cashCustomerPartyId: cashCustomerPartyId,
    );
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
