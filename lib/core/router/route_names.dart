/// Centralized route paths and names for [GoRouter].
abstract final class RouteNames {
  static const String home = '/';
  static const String ledger = '/ledger';
  static const String stock = '/stock';
  static const String reports = '/reports';
  static const String ai = '/ai';
  static const String businessProfile = '/business-profile';
  static const String ledgerPartyNew = '/ledger/party/new';
  static const String ledgerPartyEdit = '/ledger/party/:id/edit';

  static String ledgerPartyEditPath(String id) => '/ledger/party/$id/edit';

  static const String homeName = 'home';
  static const String ledgerName = 'ledger';
  static const String ledgerPartyNewName = 'ledgerPartyNew';
  static const String ledgerPartyEditName = 'ledgerPartyEdit';
  static const String stockName = 'stock';
  static const String reportsName = 'reports';
  static const String aiName = 'ai';
  static const String businessProfileName = 'businessProfile';
}
