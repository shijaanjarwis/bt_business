/// Customer, supplier, or both.
enum PartyType {
  customer('customer', 'Customer', 'Customer'),
  supplier('supplier', 'Supplier', 'Supplier'),
  both('both', 'Both', 'Dono');

  const PartyType(this.code, this.englishLabel, this.hindiLabel);

  final String code;
  final String englishLabel;
  final String hindiLabel;

  static PartyType fromCode(String code) {
    return PartyType.values.firstWhere(
      (type) => type.code == code,
      orElse: () => PartyType.customer,
    );
  }
}
