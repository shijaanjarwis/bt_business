import 'package:bt_business/features/business/domain/entities/currency.dart';
import 'package:bt_business/features/business/domain/usecases/save_business.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_business_repository.dart';

void main() {
  late FakeBusinessRepository repository;
  late SaveBusinessUseCase useCase;

  setUp(() {
    repository = FakeBusinessRepository();
    useCase = SaveBusinessUseCase(repository);
  });

  test('rejects missing business name', () async {
    final result = await useCase(
      const SaveBusinessParams(
        name: ' ',
        address: '',
        phone: '',
        email: '',
        financialYearStartMonth: 4,
        currency: BusinessCurrency.inr,
      ),
    );

    expect(result.isFailure, isTrue);
  });

  test('rejects invalid GSTIN', () async {
    final result = await useCase(
      const SaveBusinessParams(
        name: 'Bharat Traders',
        address: '',
        phone: '',
        email: '',
        gstin: 'INVALID',
        financialYearStartMonth: 4,
        currency: BusinessCurrency.inr,
      ),
    );

    expect(result.isFailure, isTrue);
  });

  test('saves valid business profile', () async {
    final result = await useCase(
      const SaveBusinessParams(
        name: 'Bharat Traders',
        address: 'Delhi',
        phone: '9876543210',
        email: 'shop@example.com',
        gstin: '27AAPFU0939F1ZV',
        financialYearStartMonth: 4,
        currency: BusinessCurrency.inr,
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.name, 'Bharat Traders');
    expect(result.valueOrNull?.gstin, '27AAPFU0939F1ZV');
    expect(repository.savedBusiness, isNotNull);
  });
}
