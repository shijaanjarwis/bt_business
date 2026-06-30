/// Direction of an opening party balance.
enum OpeningBalanceDirection {
  receivable('receivable', 'Lena hai', 'Mujhe lena hai'),
  payable('payable', 'Dena hai', 'Mujhe dena hai');

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
