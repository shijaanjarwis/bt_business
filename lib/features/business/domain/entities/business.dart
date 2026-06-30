import 'currency.dart';

/// Domain entity representing the single business profile on this device.
class Business {
  const Business({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    this.gstin,
    this.logoPath,
    required this.financialYearStartMonth,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String address;
  final String phone;
  final String email;
  final String? gstin;
  final String? logoPath;
  final int financialYearStartMonth;
  final BusinessCurrency currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  Business copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? gstin,
    String? logoPath,
    bool clearGstin = false,
    bool clearLogoPath = false,
    int? financialYearStartMonth,
    BusinessCurrency? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Business(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gstin: clearGstin ? null : (gstin ?? this.gstin),
      logoPath: clearLogoPath ? null : (logoPath ?? this.logoPath),
      financialYearStartMonth:
          financialYearStartMonth ?? this.financialYearStartMonth,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Business &&
          id == other.id &&
          name == other.name &&
          address == other.address &&
          phone == other.phone &&
          email == other.email &&
          gstin == other.gstin &&
          logoPath == other.logoPath &&
          financialYearStartMonth == other.financialYearStartMonth &&
          currency == other.currency &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        address,
        phone,
        email,
        gstin,
        logoPath,
        financialYearStartMonth,
        currency,
        createdAt,
        updatedAt,
      );
}
