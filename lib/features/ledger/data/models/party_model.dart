import '../../domain/entities/opening_balance_direction.dart';
import '../../domain/entities/party.dart';
import '../../domain/entities/party_type.dart';
import '../../../../data/local/database/tables/accounting_tables.dart';

/// Maps between [Party] entities and SQLite rows.
final class PartyModel {
  const PartyModel({required this.party});

  final Party party;

  factory PartyModel.fromMap(Map<String, Object?> map) {
    return PartyModel(
      party: Party(
        id: map[PartiesTable.id]! as String,
        businessId: map[PartiesTable.businessId]! as String,
        name: map[PartiesTable.name]! as String,
        type: PartyType.fromCode(map[PartiesTable.type]! as String),
        phone: map[PartiesTable.phone]! as String,
        address: map[PartiesTable.address]! as String? ?? '',
        gstin: map[PartiesTable.gstin] as String?,
        openingBalance: (map[PartiesTable.openingBalance] as num?)?.toDouble() ?? 0,
        balance: (map[PartiesTable.balance] as num?)?.toDouble() ?? 0,
        creditLimit: (map[PartiesTable.creditLimit] as num?)?.toDouble(),
        isActive: (map[PartiesTable.isActive] as int? ?? 1) == 1,
        openingTransactionId: map[PartiesTable.openingTransactionId] as String?,
        createdAt: DateTime.parse(map[PartiesTable.createdAt]! as String),
        updatedAt: DateTime.parse(map[PartiesTable.updatedAt]! as String),
      ),
    );
  }

  Map<String, Object?> toMap() {
    return {
      PartiesTable.id: party.id,
      PartiesTable.businessId: party.businessId,
      PartiesTable.name: party.name,
      PartiesTable.type: party.type.code,
      PartiesTable.phone: party.phone,
      PartiesTable.address: party.address,
      PartiesTable.gstin: party.gstin,
      PartiesTable.openingBalance: party.openingBalance,
      PartiesTable.balance: party.balance,
      PartiesTable.creditLimit: party.creditLimit,
      PartiesTable.isActive: party.isActive ? 1 : 0,
      PartiesTable.openingTransactionId: party.openingTransactionId,
      PartiesTable.createdAt: party.createdAt.toIso8601String(),
      PartiesTable.updatedAt: party.updatedAt.toIso8601String(),
    };
  }

  Party toEntity() => party;

  static double signedOpeningBalance({
    required double amount,
    required OpeningBalanceDirection direction,
  }) {
    if (amount == 0) return 0;
    return direction == OpeningBalanceDirection.receivable ? amount : -amount;
  }
}
