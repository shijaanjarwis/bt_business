import 'opening_balance_direction.dart';
import 'party_type.dart';

/// A customer or supplier in the business ledger.
class Party {
  const Party({
    required this.id,
    required this.businessId,
    required this.name,
    required this.type,
    required this.phone,
    required this.address,
    this.gstin,
    required this.openingBalance,
    required this.balance,
    this.creditLimit,
    required this.isActive,
    this.openingTransactionId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String businessId;
  final String name;
  final PartyType type;
  final String phone;
  final String address;
  final String? gstin;
  final double openingBalance;
  final double balance;
  final double? creditLimit;
  final bool isActive;
  final String? openingTransactionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isReceivable => balance > 0;
  bool get isPayable => balance < 0;

  OpeningBalanceDirection get openingDirection =>
      openingBalance >= 0 ? OpeningBalanceDirection.receivable : OpeningBalanceDirection.payable;

  double get openingAmount => openingBalance.abs();

  Party copyWith({
    String? id,
    String? businessId,
    String? name,
    PartyType? type,
    String? phone,
    String? address,
    String? gstin,
    bool clearGstin = false,
    double? openingBalance,
    double? balance,
    double? creditLimit,
    bool clearCreditLimit = false,
    bool? isActive,
    String? openingTransactionId,
    bool clearOpeningTransactionId = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Party(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      type: type ?? this.type,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      gstin: clearGstin ? null : (gstin ?? this.gstin),
      openingBalance: openingBalance ?? this.openingBalance,
      balance: balance ?? this.balance,
      creditLimit: clearCreditLimit ? null : (creditLimit ?? this.creditLimit),
      isActive: isActive ?? this.isActive,
      openingTransactionId: clearOpeningTransactionId
          ? null
          : (openingTransactionId ?? this.openingTransactionId),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Party &&
          id == other.id &&
          businessId == other.businessId &&
          name == other.name &&
          type == other.type &&
          phone == other.phone &&
          address == other.address &&
          gstin == other.gstin &&
          openingBalance == other.openingBalance &&
          balance == other.balance &&
          creditLimit == other.creditLimit &&
          isActive == other.isActive &&
          openingTransactionId == other.openingTransactionId &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        businessId,
        name,
        type,
        phone,
        address,
        gstin,
        openingBalance,
        balance,
        creditLimit,
        isActive,
        openingTransactionId,
        createdAt,
        updatedAt,
      );
}
