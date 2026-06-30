/// SQLite column names for the [business] table.
abstract final class BusinessTable {
  static const String tableName = 'business';

  static const String id = 'id';
  static const String name = 'name';
  static const String address = 'address';
  static const String phone = 'phone';
  static const String email = 'email';
  static const String gstin = 'gstin';
  static const String logoPath = 'logo_path';
  static const String financialYearStartMonth = 'financial_year_start_month';
  static const String currencyCode = 'currency_code';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}
