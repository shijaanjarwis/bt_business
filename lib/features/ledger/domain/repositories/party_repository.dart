import '../../../../core/errors/result.dart';
import '../entities/opening_balance_direction.dart';
import '../entities/party.dart';
import '../entities/party_type.dart';

/// Persistence contract for ledger parties.
abstract interface class PartyRepository {
  Future<Result<List<Party>>> getParties({bool activeOnly = false});

  Future<Result<List<Party>>> searchParties(String query, {bool activeOnly = false});

  Future<Result<Party?>> getParty(String id);

  Future<Result<Party>> saveParty(SavePartyInput input);

  Future<Result<void>> deleteParty(String id);

  Future<Result<bool>> hasTransactions(String partyId);
}

/// Domain input for creating or updating a party.
class SavePartyInput {
  const SavePartyInput({
    this.id,
    required this.name,
    required this.type,
    required this.phone,
    required this.address,
    this.gstin,
    required this.openingAmount,
    required this.openingDirection,
    this.creditLimit,
    required this.isActive,
    this.existingCreatedAt,
    this.existingOpeningTransactionId,
    this.existingBalance,
    this.allowOpeningUpdate = false,
  });

  final String? id;
  final String name;
  final PartyType type;
  final String phone;
  final String address;
  final String? gstin;
  final double openingAmount;
  final OpeningBalanceDirection openingDirection;
  final double? creditLimit;
  final bool isActive;
  final DateTime? existingCreatedAt;
  final String? existingOpeningTransactionId;
  final double? existingBalance;
  final bool allowOpeningUpdate;
}
