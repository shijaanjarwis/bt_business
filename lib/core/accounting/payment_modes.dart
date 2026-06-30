/// How a sale invoice is settled.
enum PaymentMode {
  cash('cash', 'Cash', 'Cash'),
  credit('credit', 'Credit', 'Udhaar');

  const PaymentMode(this.code, this.englishLabel, this.hindiLabel);

  final String code;
  final String englishLabel;
  final String hindiLabel;

  static PaymentMode fromCode(String code) {
    return PaymentMode.values.firstWhere(
      (mode) => mode.code == code,
      orElse: () => PaymentMode.cash,
    );
  }
}
