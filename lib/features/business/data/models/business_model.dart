import '../../domain/entities/business.dart';
import '../../domain/entities/currency.dart';
import '../datasources/business_table.dart';

/// Maps between [Business] entities and SQLite rows.
final class BusinessModel {
  const BusinessModel({required this.business});

  final Business business;

  factory BusinessModel.fromMap(Map<String, Object?> map) {
    return BusinessModel(
      business: Business(
        id: map[BusinessTable.id]! as String,
        name: map[BusinessTable.name]! as String,
        address: map[BusinessTable.address]! as String,
        phone: map[BusinessTable.phone]! as String,
        email: map[BusinessTable.email]! as String,
        gstin: map[BusinessTable.gstin] as String?,
        logoPath: map[BusinessTable.logoPath] as String?,
        financialYearStartMonth:
            map[BusinessTable.financialYearStartMonth]! as int,
        currency: BusinessCurrency.fromCode(
          map[BusinessTable.currencyCode]! as String,
        ),
        createdAt: DateTime.parse(map[BusinessTable.createdAt]! as String),
        updatedAt: DateTime.parse(map[BusinessTable.updatedAt]! as String),
      ),
    );
  }

  Map<String, Object?> toMap() {
    return {
      BusinessTable.id: business.id,
      BusinessTable.name: business.name,
      BusinessTable.address: business.address,
      BusinessTable.phone: business.phone,
      BusinessTable.email: business.email,
      BusinessTable.gstin: business.gstin,
      BusinessTable.logoPath: business.logoPath,
      BusinessTable.financialYearStartMonth: business.financialYearStartMonth,
      BusinessTable.currencyCode: business.currency.code,
      BusinessTable.createdAt: business.createdAt.toIso8601String(),
      BusinessTable.updatedAt: business.updatedAt.toIso8601String(),
    };
  }

  Business toEntity() => business;
}
