import '../../../../core/errors/result.dart';
import '../entities/opening_balance_direction.dart';
import '../entities/party.dart';
import '../entities/party_history_entry.dart';
import '../entities/party_type.dart';

/// Persistence contract for hisaab parties.
abstract interface class PartyRepository {
  Future<Result<List<Party>>> getParties({bool activeOnly = false});

  Future<Result<List<Party>>> searchParties(String query, {bool activeOnly = false});

  Future<Result<Party?>> getParty(String id);

  Future<Result<Party>> saveParty(SavePartyInput input);

  Future<Result<void>> deleteParty(String id);

  Future<Result<bool>> hasTransactions(String partyId);

  Future<Result<List<PartyHistoryEntry>>> getPartyHistory(String partyId);

  Future<Result<void>> recordPaymentReceived(RecordPaymentInput input);

  Future<Result<void>> recordPaymentPaid(RecordPaymentInput input);
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

/// Input for recording jama or payment on a party hisaab.
class RecordPaymentInput {
  const RecordPaymentInput({
    required this.partyId,
    required this.amount,
    required this.date,
    this.note,
  });

  final String partyId;
  final double amount;
  final DateTime date;
  final String? note;
}
