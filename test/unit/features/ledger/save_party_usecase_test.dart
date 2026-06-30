import 'package:bt_business/core/errors/failures.dart';
import 'package:bt_business/core/errors/result.dart';
import 'package:bt_business/features/ledger/domain/entities/opening_balance_direction.dart';
import 'package:bt_business/features/ledger/domain/entities/party.dart';
import 'package:bt_business/features/ledger/domain/entities/party_type.dart';
import 'package:bt_business/features/ledger/domain/repositories/party_repository.dart';
import 'package:bt_business/features/ledger/domain/usecases/save_party.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePartyRepository implements PartyRepository {
  SavePartyInput? lastInput;

  @override
  Future<Result<List<Party>>> getParties({bool activeOnly = false}) {
    throw UnimplementedError();
  }

  @override
  Future<Result<List<Party>>> searchParties(
    String query, {
    bool activeOnly = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<Party?>> getParty(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Result<Party>> saveParty(SavePartyInput input) async {
    lastInput = input;
    return Success(
      Party(
        id: 'party-1',
        businessId: 'biz-1',
        name: input.name,
        type: input.type,
        phone: input.phone,
        address: input.address,
        gstin: input.gstin,
        openingBalance: input.openingAmount,
        balance: input.openingAmount,
        creditLimit: input.creditLimit,
        isActive: input.isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<Result<void>> deleteParty(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Result<bool>> hasTransactions(String partyId) {
    throw UnimplementedError();
  }
}

void main() {
  test('SavePartyUseCase validates required fields', () async {
    final repository = _FakePartyRepository();
    final useCase = SavePartyUseCase(repository);

    final result = await useCase(
      SavePartyInput(
        name: '',
        type: PartyType.customer,
        phone: '',
        address: '',
        openingAmount: 0,
        openingDirection: OpeningBalanceDirection.receivable,
        isActive: true,
      ),
    );

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull, isA<ValidationFailure>());
  });

  test('SavePartyUseCase normalizes phone and gstin', () async {
    final repository = _FakePartyRepository();
    final useCase = SavePartyUseCase(repository);

    final result = await useCase(
      SavePartyInput(
        name: 'Ramesh',
        type: PartyType.customer,
        phone: '+91 98765 43210',
        address: 'Delhi',
        gstin: '07aaaaa0000a1z5',
        openingAmount: 100,
        openingDirection: OpeningBalanceDirection.receivable,
        isActive: true,
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(repository.lastInput?.phone, '9876543210');
    expect(repository.lastInput?.gstin, '07AAAAA0000A1Z5');
  });
}
