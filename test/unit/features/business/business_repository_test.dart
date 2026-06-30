import 'package:bt_business/data/local/database/migrations/migration_runner.dart';
import 'package:bt_business/features/business/data/datasources/business_local_datasource.dart';
import 'package:bt_business/features/business/data/datasources/business_table.dart';
import 'package:bt_business/features/business/data/repositories/business_repository_impl.dart';
import 'package:bt_business/features/business/domain/entities/business.dart';
import 'package:bt_business/features/business/domain/entities/currency.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late BusinessRepositoryImpl repository;

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 2,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: MigrationRunner.onCreate,
      onUpgrade: MigrationRunner.onUpgrade,
    );
    repository = BusinessRepositoryImpl(BusinessLocalDataSource(db));
  });

  tearDown(() async {
    await db.close();
  });

  Business buildBusiness({String id = 'biz-1'}) {
    final now = DateTime(2026, 6, 30);
    return Business(
      id: id,
      name: 'Bharat Traders',
      address: 'Delhi',
      phone: '9876543210',
      email: 'shop@example.com',
      gstin: '27AAPFU0939F1ZV',
      financialYearStartMonth: 4,
      currency: BusinessCurrency.inr,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('returns null when no profile exists', () async {
    final result = await repository.getBusiness();
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, isNull);
  });

  test('saves and reads business profile', () async {
    final business = buildBusiness();
    final saveResult = await repository.saveBusiness(business);

    expect(saveResult.isSuccess, isTrue);
    expect(saveResult.valueOrNull?.name, 'Bharat Traders');

    final getResult = await repository.getBusiness();
    expect(getResult.valueOrNull?.gstin, '27AAPFU0939F1ZV');
  });

  test('updates existing business profile', () async {
    await repository.saveBusiness(buildBusiness());
    final updated = buildBusiness().copyWith(name: 'Updated Traders');
    final result = await repository.saveBusiness(updated);

    expect(result.valueOrNull?.name, 'Updated Traders');

    final rows = await db.query(BusinessTable.tableName);
    expect(rows, hasLength(1));
  });

  test('deletes business profile', () async {
    await repository.saveBusiness(buildBusiness());
    final deleteResult = await repository.deleteBusiness('biz-1');

    expect(deleteResult.isSuccess, isTrue);

    final getResult = await repository.getBusiness();
    expect(getResult.valueOrNull, isNull);
  });
}
