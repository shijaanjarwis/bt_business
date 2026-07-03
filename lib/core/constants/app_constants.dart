abstract final class AppConstants {
  static const String appName = 'BT Business';
  static const String databaseName = 'bt_business.db';
  static const int databaseVersion = 9;

  /// Default page size for register list SQL queries.
  static const int registerListLimit = 500;

  /// Debounce delay for instant search fields.
  static const Duration searchDebounce = Duration(milliseconds: 250);
}
