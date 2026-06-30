import 'package:bt_business/features/ledger/data/datasources/party_local_datasource.dart';
import 'package:bt_business/features/ledger/data/repositories/party_repository_impl.dart';
import 'package:bt_business/features/ledger/data/services/opening_balance_posting_service.dart';
import 'package:bt_business/features/ledger/domain/entities/opening_balance_direction.dart';
import 'package:bt_business/features/ledger/domain/entities/party_type.dart';
import 'package:bt_business/features/ledger/domain/repositories/party_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/dashboard_test_data.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late PartyRepository repository;

  setUp(() async {
    db = await createTestDatabase();
    await seedTestBusiness(db);
    repository = PartyRepositoryImpl(
      PartyLocalDataSource(db),
      OpeningBalancePostingService(db),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('saveParty creates customer with receivable opening balance', () async {
    final result = await repository.saveParty(
      SavePartyInput(
        name: 'Ramesh Traders',
        type: PartyType.customer,
        phone: '9876543210',
        address: 'Delhi',
        gstin: '07AAAAA0000A1Z5',
        openingAmount: 2500,
        openingDirection: OpeningBalanceDirection.receivable,
        creditLimit: 5000,
        isActive: true,
      ),
    );

    expect(result.isSuccess, isTrue);
    final party = result.valueOrNull!;
    expect(party.name, 'Ramesh Traders');
    expect(party.balance, 2500);
    expect(party.openingBalance, 2500);
    expect(party.openingTransactionId, isNotNull);
  });

  test('searchParties finds by name', () async {
    await repository.saveParty(
      SavePartyInput(
        name: 'Alpha Store',
        type: PartyType.customer,
        phone: '9876543210',
        address: '',
        openingAmount: 0,
        openingDirection: OpeningBalanceDirection.receivable,
        isActive: true,
      ),
    );
    await repository.saveParty(
      SavePartyInput(
        name: 'Beta Suppliers',
        type: PartyType.supplier,
        phone: '9123456780',
        address: '',
        openingAmount: 0,
        openingDirection: OpeningBalanceDirection.payable,
        isActive: true,
      ),
    );

    final result = await repository.searchParties('Alpha');
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, hasLength(1));
    expect(result.valueOrNull!.first.name, 'Alpha Store');
  });

  test('deleteParty removes party without other transactions', () async {
    final saved = await repository.saveParty(
      SavePartyInput(
        name: 'Temp Party',
        type: PartyType.customer,
        phone: '9876543210',
        address: '',
        openingAmount: 0,
        openingDirection: OpeningBalanceDirection.receivable,
        isActive: true,
      ),
    );

    final deleteResult = await repository.deleteParty(saved.valueOrNull!.id);
    expect(deleteResult.isSuccess, isTrue);

    final fetch = await repository.getParty(saved.valueOrNull!.id);
    expect(fetch.valueOrNull, isNull);
  });
}
