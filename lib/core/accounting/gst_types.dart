/// GST supply type for splitting CGST/SGST vs IGST.
enum GstType {
  intra('intra', 'Intra-state (CGST + SGST)', 'Same state — CGST + SGST'),
  inter('inter', 'Inter-state (IGST)', 'Dusre state — IGST');

  const GstType(this.code, this.englishLabel, this.hindiLabel);

  final String code;
  final String englishLabel;
  final String hindiLabel;

  static GstType fromCode(String code) {
    return GstType.values.firstWhere(
      (type) => type.code == code,
      orElse: () => GstType.intra,
    );
  }
}
