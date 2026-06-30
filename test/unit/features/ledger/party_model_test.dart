import 'package:bt_business/features/ledger/data/models/party_model.dart';
import 'package:bt_business/features/ledger/domain/entities/opening_balance_direction.dart';
import 'package:bt_business/features/ledger/domain/entities/party.dart';
import 'package:bt_business/features/ledger/domain/entities/party_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 1, 15);

  test('PartyModel round-trips SQLite map', () {
    final party = Party(
      id: 'party-1',
      businessId: 'biz-1',
      name: 'Ramesh Traders',
      type: PartyType.customer,
      phone: '9876543210',
      address: 'Delhi',
      gstin: '07AAAAA0000A1Z5',
      openingBalance: 5000,
      balance: 5000,
      creditLimit: 10000,
      isActive: true,
      openingTransactionId: 'tx-1',
      createdAt: now,
      updatedAt: now,
    );

    final map = PartyModel(party: party).toMap();
    final restored = PartyModel.fromMap(map).toEntity();

    expect(restored, party);
  });

  test('signedOpeningBalance applies direction', () {
    expect(
      PartyModel.signedOpeningBalance(
        amount: 100,
        direction: OpeningBalanceDirection.receivable,
      ),
      100,
    );
    expect(
      PartyModel.signedOpeningBalance(
        amount: 100,
        direction: OpeningBalanceDirection.payable,
      ),
      -100,
    );
  });
}
