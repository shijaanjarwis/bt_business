/// Permanent bilingual label pair — English primary, daily spoken Hindi below.
///
/// Assistant language settings never replace these. Shown on every screen.
class AppLabelPair {
  const AppLabelPair(this.english, this.hindi);

  final String english;

  /// Daily shopkeeper Hindi — never formal Sanskritized terms.
  final String hindi;
}

/// Central registry of mandatory bilingual UI labels.
///
/// Use via [BilingualLabel.fromKey] or direct lookup. English is always primary.
abstract final class LabelRegistry {
  static const sale = AppLabelPair('Sale', 'Bikri');
  static const purchase = AppLabelPair('Purchase', 'Kharid');
  static const goods = AppLabelPair('Goods', 'Maal');
  static const item = AppLabelPair('Item', 'Maal');
  static const expense = AppLabelPair('Expense', 'Kharcha');
  static const ledger = AppLabelPair('Ledger', 'Hisaab');
  static const outstanding = AppLabelPair('Outstanding', 'Baaki');
  static const remaining = AppLabelPair('Remaining', 'Baaki');
  static const receive = AppLabelPair('Receive', 'Paise Mile');
  static const payment = AppLabelPair('Payment', 'Paisa Diye');
  static const cash = AppLabelPair('Cash', 'Cash');
  static const upi = AppLabelPair('UPI', 'UPI');
  static const bank = AppLabelPair('Bank', 'Bank');
  static const party = AppLabelPair('Party', 'Party');
  static const stock = AppLabelPair('Stock', 'Maal');
  static const credit = AppLabelPair('Credit', 'Udhaar');
  static const dashboard = AppLabelPair('Dashboard', 'Home');
  static const save = AppLabelPair('Save', 'Save Karein');
  static const edit = AppLabelPair('Edit', 'Edit Karein');
  static const delete = AppLabelPair('Delete', 'Delete Karein');
  static const voice = AppLabelPair('Voice', 'Voice');
  static const voiceGreetingLanguage = AppLabelPair(
    'Voice & Greeting Language',
    'Awaz aur Greeting',
  );
  static const settings = AppLabelPair('Settings', 'Settings');
  static const total = AppLabelPair('Total', 'Total');
  static const notes = AppLabelPair('Notes', 'Note');
  static const date = AppLabelPair('Date', 'Date');

  static const _entries = <String, AppLabelPair>{
    'sale': sale,
    'purchase': purchase,
    'goods': goods,
    'item': item,
    'expense': expense,
    'ledger': ledger,
    'outstanding': outstanding,
    'remaining': remaining,
    'receive': receive,
    'payment': payment,
    'cash': cash,
    'upi': upi,
    'bank': bank,
    'party': party,
    'stock': stock,
    'credit': credit,
    'dashboard': dashboard,
    'save': save,
    'edit': edit,
    'delete': delete,
    'voice': voice,
    'voiceGreetingLanguage': voiceGreetingLanguage,
    'settings': settings,
    'total': total,
    'notes': notes,
    'date': date,
  };

  static AppLabelPair get(String key) =>
      _entries[key] ?? AppLabelPair(key, key);

  static AppLabelPair? maybeGet(String key) => _entries[key];
}
