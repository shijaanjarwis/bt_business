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
      address: input.address.trim(),
      gstin: _normalizeGstin(input.gstin),
      openingAmount: input.openingAmount,
      openingDirection: input.openingDirection,
      creditLimit: input.creditLimit,
      isActive: input.isActive,
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

    final phoneError = Validators.requiredIndianPhone(input.phone);
    if (phoneError != null) return ValidationFailure(phoneError);

    final gstinError = Validators.gstin(input.gstin);
    if (gstinError != null) return ValidationFailure(gstinError);

    if (input.openingAmount < 0) {
      return const ValidationFailure('Opening balance cannot be negative');
    }

    if (input.creditLimit != null && input.creditLimit! < 0) {
      return const ValidationFailure('Credit limit cannot be negative');
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

  String? _normalizeGstin(String? gstin) {
    final trimmed = gstin?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed.toUpperCase();
  }
}
