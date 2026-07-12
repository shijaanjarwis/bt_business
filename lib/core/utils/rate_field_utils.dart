/// Helpers for rate input fields — empty by default, no forced 0.0 prefix.
abstract final class RateFieldUtils {
  static String initialText(double rate) {
    if (rate <= 0) return '';
    if (rate == rate.roundToDouble()) {
      return rate.round().toString();
    }
    return rate.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  static double parse(String text) {
    final trimmed = text.replaceAll(',', '').trim();
    if (trimmed.isEmpty) return 0;
    return double.tryParse(trimmed) ?? 0;
  }
}
