/// Supported business currencies — extensible for future markets.
enum BusinessCurrency {
  inr('INR', 'Indian Rupee', '₹');

  const BusinessCurrency(this.code, this.label, this.symbol);

  final String code;
  final String label;
  final String symbol;

  static BusinessCurrency fromCode(String code) {
    return BusinessCurrency.values.firstWhere(
      (currency) => currency.code == code.toUpperCase(),
      orElse: () => BusinessCurrency.inr,
    );
  }
}
