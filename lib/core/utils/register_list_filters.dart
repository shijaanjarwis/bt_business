import '../accounting/payment_modes.dart';

/// Shared SQL filter params for register list queries.
class RegisterListFilters {
  const RegisterListFilters({
    this.fromDate,
    this.toDate,
    this.paymentMode,
    this.minDueAmount,
    this.minPaidAmount,
  });

  final DateTime? fromDate;
  final DateTime? toDate;
  final PaymentMode? paymentMode;
  final double? minDueAmount;
  final double? minPaidAmount;
}

class SearchRegisterParams {
  const SearchRegisterParams({
    required this.query,
    this.filters = const RegisterListFilters(),
  });

  final String query;
  final RegisterListFilters filters;
}
