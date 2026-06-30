import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../core/utils/validators.dart';
import '../entities/business.dart';
import '../entities/currency.dart';
import '../entities/financial_year.dart';
import '../repositories/business_repository.dart';

/// Input for creating or updating the business profile.
class SaveBusinessParams {
  const SaveBusinessParams({
    this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    this.gstin,
    this.logoPath,
    this.removeLogo = false,
    required this.financialYearStartMonth,
    required this.currency,
    this.existingCreatedAt,
  });

  final String? id;
  final String name;
  final String address;
  final String phone;
  final String email;
  final String? gstin;
  final String? logoPath;
  final bool removeLogo;
  final int financialYearStartMonth;
  final BusinessCurrency currency;
  final DateTime? existingCreatedAt;
}

final class SaveBusinessUseCase implements UseCase<Business, SaveBusinessParams> {
  const SaveBusinessUseCase(this._repository);

  final BusinessRepository _repository;

  @override
  Future<Result<Business>> call(SaveBusinessParams params) async {
    final validationError = _validate(params);
    if (validationError != null) {
      return Error(validationError);
    }

    final now = DateTime.now();
    final business = Business(
      id: params.id ?? IdGenerator.newId(),
      name: params.name.trim(),
      address: params.address.trim(),
      phone: params.phone.trim(),
      email: params.email.trim(),
      gstin: _normalizeGstin(params.gstin),
      logoPath: params.removeLogo ? null : params.logoPath,
      financialYearStartMonth: params.financialYearStartMonth,
      currency: params.currency,
      createdAt: params.existingCreatedAt ?? now,
      updatedAt: now,
    );

    return _repository.saveBusiness(business);
  }

  Failure? _validate(SaveBusinessParams params) {
    final nameError = Validators.requiredText(
      params.name,
      fieldName: 'Business name',
    );
    if (nameError != null) return ValidationFailure(nameError);

    final gstinError = Validators.gstin(params.gstin);
    if (gstinError != null) return ValidationFailure(gstinError);

    final phoneError = Validators.indianPhone(params.phone);
    if (phoneError != null) return ValidationFailure(phoneError);

    final emailError = Validators.email(params.email);
    if (emailError != null) return ValidationFailure(emailError);

    if (!FinancialYear.startMonths.contains(params.financialYearStartMonth)) {
      return const ValidationFailure('Select a valid financial year start month');
    }

    return null;
  }

  String? _normalizeGstin(String? gstin) {
    final trimmed = gstin?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed.toUpperCase();
  }
}
