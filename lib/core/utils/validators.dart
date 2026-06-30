/// Input validation helpers for Indian business data.
abstract final class Validators {
  static final RegExp _gstinPattern = RegExp(
    r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
  );

  static final RegExp _hsnSacPattern = RegExp(r'^\d{4,8}$');

  static final RegExp _indianPhonePattern = RegExp(r'^[6-9]\d{9}$');

  static String? gstin(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final normalized = value.trim().toUpperCase();
    if (!_gstinPattern.hasMatch(normalized)) {
      return 'Enter a valid 15-character GSTIN';
    }
    return null;
  }

  static String? hsnSac(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    if (!_hsnSacPattern.hasMatch(value.trim())) {
      return 'Enter a valid 4–8 digit HSN/SAC code';
    }
    return null;
  }

  static String? indianPhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    var digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    }
    if (!_indianPhonePattern.hasMatch(digits)) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailPattern.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? requiredText(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? positiveAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }

    final amount = double.tryParse(value.replaceAll(',', '').trim());
    if (amount == null || amount <= 0) {
      return 'Enter a valid amount greater than zero';
    }
    return null;
  }
}
