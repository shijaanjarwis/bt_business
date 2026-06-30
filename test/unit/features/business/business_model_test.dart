import 'package:bt_business/features/business/data/models/business_model.dart';
import 'package:bt_business/features/business/domain/entities/business.dart';
import 'package:bt_business/features/business/domain/entities/currency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BusinessModel maps to and from sqlite row', () {
    final now = DateTime(2026, 6, 30, 10, 30);
    final business = Business(
      id: 'biz-1',
      name: 'Bharat Traders',
      address: 'Delhi',
      phone: '9876543210',
      email: 'shop@example.com',
      gstin: '27AAPFU0939F1ZV',
      logoPath: '/tmp/logo.png',
      financialYearStartMonth: 4,
      currency: BusinessCurrency.inr,
      createdAt: now,
      updatedAt: now,
    );

    final map = BusinessModel(business: business).toMap();
    final restored = BusinessModel.fromMap(map).toEntity();

    expect(restored, business);
  });
}
