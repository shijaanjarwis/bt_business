import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/validators.dart';
import '../entities/party.dart';
import '../repositories/party_repository.dart';

final class SavePartyUseCase implements UseCase<Party, SavePartyInput> {
  const SavePartyUseCase(this._repository);

  final PartyRepository _repository;

  @override
  Future<Result<Party>> call(SavePartyInput input) async {
    final validationError = _validate(input);
    if (validationError != null) {
      return Error(validationError);
    }

    final normalized = SavePartyInput(
      id: input.id,
      name: input.name.trim(),
      type: input.type,
      phone: _normalizePhone(input.phone),
      address: '',
      gstin: null,
      openingAmount: input.openingAmount,
      openingDirection: input.openingDirection,
      creditLimit: null,
      isActive: true,
      existingCreatedAt: input.existingCreatedAt,
      existingOpeningTransactionId: input.existingOpeningTransactionId,
      existingBalance: input.existingBalance,
      allowOpeningUpdate: input.allowOpeningUpdate,
    );

    return _repository.saveParty(normalized);
  }

  Failure? _validate(SavePartyInput input) {
    final nameError = Validators.requiredText(input.name, fieldName: 'Name');
    if (nameError != null) return ValidationFailure(nameError);

    final phone = input.phone.trim();
    if (phone.isNotEmpty) {
      final phoneError = Validators.indianPhone(phone);
      if (phoneError != null) return ValidationFailure(phoneError);
    }

    if (input.openingAmount < 0) {
      return const ValidationFailure('Pehle se baaki amount negative nahi ho sakti');
    }

    return null;
  }

  String _normalizePhone(String phone) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    }
    return digits;
  }
}
