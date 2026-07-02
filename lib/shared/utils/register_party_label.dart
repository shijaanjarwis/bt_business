import '../../data/local/database/seeders/cash_customer_seeder.dart';

/// Display name for register cards — real party name, or cash label when walk-in.
abstract final class RegisterPartyLabel {
  static bool isCashCustomerParty({
    required String partyId,
    required String partyName,
    String? cashCustomerPartyId,
  }) {
    if (partyName.trim().isEmpty) return true;
    if (cashCustomerPartyId != null && partyId == cashCustomerPartyId) {
      return true;
    }
    return partyName == CashCustomerSeeder.displayName;
  }

  static String saleTitle({
    required String partyId,
    required String partyName,
    String? cashCustomerPartyId,
  }) {
    if (isCashCustomerParty(
      partyId: partyId,
      partyName: partyName,
      cashCustomerPartyId: cashCustomerPartyId,
    )) {
      return 'Cash Sale';
    }
    return partyName.trim();
  }

  static String purchaseTitle({
    required String partyId,
    required String partyName,
    String? cashCustomerPartyId,
  }) {
    if (isCashCustomerParty(
      partyId: partyId,
      partyName: partyName,
      cashCustomerPartyId: cashCustomerPartyId,
    )) {
      return 'Cash Purchase';
    }
    return partyName.trim();
  }

  static String paymentTitle({
    required String partyId,
    required String partyName,
    String? cashCustomerPartyId,
  }) {
    if (isCashCustomerParty(
      partyId: partyId,
      partyName: partyName,
      cashCustomerPartyId: cashCustomerPartyId,
    )) {
      return 'Cash Customer';
    }
    return partyName.trim();
  }
}
