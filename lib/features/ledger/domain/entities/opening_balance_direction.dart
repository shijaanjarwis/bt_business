/// Direction of an opening party balance.
enum OpeningBalanceDirection {
  receivable('receivable', 'Receivable (Lena)', 'Lena — Paise lene hain'),
  payable('payable', 'Payable (Dena)', 'Dena — Paise dene hain');

  const OpeningBalanceDirection(
    this.code,
    this.englishLabel,
    this.hindiLabel,
  );

  final String code;
  final String englishLabel;
  final String hindiLabel;

  static OpeningBalanceDirection fromCode(String code) {
    return OpeningBalanceDirection.values.firstWhere(
      (direction) => direction.code == code,
      orElse: () => OpeningBalanceDirection.receivable,
    );
  }
}
