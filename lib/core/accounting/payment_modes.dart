/// How a sale or purchase entry is settled.
enum PaymentMode {
  cash('cash', 'Paid now', 'Abhi mila'),
  credit('credit', 'Udhaar', 'Baad mein');

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
