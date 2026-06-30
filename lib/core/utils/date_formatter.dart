import 'package:intl/intl.dart';

/// Date and time formatting for Indian business contexts.
abstract final class DateFormatter {
  static final DateFormat _displayDate = DateFormat('EEEE, d MMMM');
  static final DateFormat _shortDate = DateFormat('d MMM yyyy');
  static final DateFormat _isoDate = DateFormat('yyyy-MM-dd');

  static String displayDate(DateTime date) => _displayDate.format(date);

  static String shortDate(DateTime date) => _shortDate.format(date);

  static String isoDate(DateTime date) => _isoDate.format(date);

  static DateTime? parseIsoDate(String value) {
    try {
      return _isoDate.parseStrict(value);
    } on FormatException {
      return null;
    }
  }
}
