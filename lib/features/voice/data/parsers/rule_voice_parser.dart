import '../../../../core/accounting/payment_breakdown.dart';
import '../../domain/voice_draft.dart';
import '../../domain/voice_intent_type.dart';
import '../../domain/voice_parser_port.dart';

/// Rule-based Hindi/English shopkeeper voice parser — v1.
final class RuleVoiceParser implements VoiceParserPort {
  @override
  VoiceParseResult parse(String text, {DateTime? referenceDate}) {
    final normalized = _normalize(text);
    if (normalized.isEmpty) {
      return VoiceParseResult(
        draft: VoiceDraft(intent: VoiceIntentType.unknown, rawText: text),
        clarification: const VoiceClarification(
          question: 'Kuch boliye — kya karna hai?',
          field: VoiceClarificationField.intent,
        ),
      );
    }

    final reference = referenceDate ?? DateTime.now();
    final intent = _detectIntent(normalized);
    final party = _extractParty(normalized);
    final itemInfo = _extractItemBlock(normalized);
    final payments = _extractPayments(normalized);
    final reminder = _extractReminderDate(normalized, reference);
    final amounts = _extractStandaloneAmounts(normalized);

    var draft = VoiceDraft(
      intent: intent,
      rawText: text,
      partyName: party,
      itemName: itemInfo.itemName,
      unit: itemInfo.unit,
      quantity: itemInfo.quantity,
      rate: itemInfo.rate,
      amount: amounts.firstOrNull,
      paymentBreakdown: payments,
      reminderDate: reminder,
    );

    draft = _applyIntentDefaults(draft, normalized);

    final clarification = _validateDraft(draft);
    return VoiceParseResult(draft: draft, clarification: clarification);
  }

  VoiceDraft _applyIntentDefaults(VoiceDraft draft, String normalized) {
    switch (draft.intent) {
      case VoiceIntentType.expense:
        final name = draft.expenseName ?? draft.itemName ?? _extractExpenseName(normalized);
        return draft.copyWith(expenseName: name, itemName: null);
      case VoiceIntentType.createParty:
        final name = draft.partyName ?? _extractCreatePartyName(normalized);
        return draft.copyWith(partyName: name);
      case VoiceIntentType.createItem:
        return draft;
      case VoiceIntentType.paymentReceived:
      case VoiceIntentType.paymentPaid:
        if (draft.amount == null && draft.paymentBreakdown.paidTotal > 0) {
          return draft.copyWith(amount: draft.paymentBreakdown.paidTotal);
        }
        return draft;
      default:
        return draft;
    }
  }

  VoiceClarification? _validateDraft(VoiceDraft draft) {
    switch (draft.intent) {
      case VoiceIntentType.sale:
      case VoiceIntentType.purchase:
        if (draft.partyName == null || draft.partyName!.trim().isEmpty) {
          return const VoiceClarification(
            question: 'Kis party ke liye?',
            field: VoiceClarificationField.party,
          );
        }
        if (draft.itemName == null || draft.itemName!.trim().isEmpty) {
          return const VoiceClarification(
            question: 'Kaunsa maal?',
            field: VoiceClarificationField.item,
          );
        }
        if (draft.quantity == null || draft.quantity! <= 0) {
          return const VoiceClarification(
            question: 'Kitna maal?',
            field: VoiceClarificationField.quantity,
          );
        }
        if (draft.rate == null || draft.rate! <= 0) {
          return const VoiceClarification(
            question: 'Rate kitna hai?',
            field: VoiceClarificationField.rate,
          );
        }
        return null;
      case VoiceIntentType.paymentReceived:
      case VoiceIntentType.paymentPaid:
        if (draft.partyName == null || draft.partyName!.trim().isEmpty) {
          return const VoiceClarification(
            question: 'Kis party se / ko?',
            field: VoiceClarificationField.party,
          );
        }
        final amount = draft.amount ?? draft.paymentBreakdown.paidTotal;
        if (amount <= 0) {
          return const VoiceClarification(
            question: 'Kitne rupaye?',
            field: VoiceClarificationField.amount,
          );
        }
        return null;
      case VoiceIntentType.expense:
        if (draft.expenseName == null || draft.expenseName!.trim().isEmpty) {
          return const VoiceClarification(
            question: 'Kis cheez ka kharcha?',
            field: VoiceClarificationField.expenseName,
          );
        }
        if ((draft.amount ?? 0) <= 0) {
          return const VoiceClarification(
            question: 'Kitne rupaye ka kharcha?',
            field: VoiceClarificationField.amount,
          );
        }
        return null;
      case VoiceIntentType.createParty:
        if (draft.partyName == null || draft.partyName!.trim().isEmpty) {
          return const VoiceClarification(
            question: 'Party ka naam kya hai?',
            field: VoiceClarificationField.party,
          );
        }
        return null;
      case VoiceIntentType.createItem:
        if (draft.itemName == null || draft.itemName!.trim().isEmpty) {
          return const VoiceClarification(
            question: 'Maal ka naam kya hai?',
            field: VoiceClarificationField.item,
          );
        }
        if (draft.unit == null || draft.unit!.trim().isEmpty) {
          return const VoiceClarification(
            question: 'Unit kya hai? (jaise Kg, Pcs)',
            field: VoiceClarificationField.unit,
          );
        }
        return null;
      case VoiceIntentType.unknown:
        return const VoiceClarification(
          question: 'Ye bikri hai, kharid, paisa mila/diya, ya kharcha?',
          field: VoiceClarificationField.intent,
        );
    }
  }

  VoiceParseResult revalidate(VoiceDraft draft) {
    return VoiceParseResult(
      draft: draft,
      clarification: _validateDraft(draft),
    );
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('₹', ' rupaye ')
        .replaceAll(RegExp(r'[^\w\s\u0900-\u097F.]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  VoiceIntentType _detectIntent(String text) {
    if (_hasAny(text, ['party banao', 'naam ki party', 'nayi party', 'new party'])) {
      return VoiceIntentType.createParty;
    }
    if (_hasAny(text, ['maal banao', 'item banao', 'naya maal', 'new item'])) {
      return VoiceIntentType.createItem;
    }
    if (_hasAny(text, ['kharch', 'kharcha', 'expense'])) {
      return VoiceIntentType.expense;
    }
    if (_hasAny(text, ['mile', 'mila', 'mil gaye', 'mil gaya', 'jama', 'received', 'receive'])) {
      if (!_hasAny(text, ['bechi', 'beche', 'becha', 'bikri', 'sale', 'kharid'])) {
        return VoiceIntentType.paymentReceived;
      }
    }
    if (_hasAny(text, ['diye', 'diya', 'de diye', 'de diya', 'payment paid', 'paid to'])) {
      return VoiceIntentType.paymentPaid;
    }
    if (_hasAny(text, ['kharid', 'kharidi', 'kharida', 'purchase', 'liya', 'liye', 'manga'])) {
      return VoiceIntentType.purchase;
    }
    if (_hasAny(text, ['bechi', 'beche', 'becha', 'bikri', 'sale', 'sold', 'bech di', 'bech diya'])) {
      return VoiceIntentType.sale;
    }
    if (text.contains(' ko ') && _hasAny(text, ['kilo', 'kg', 'piece', 'pcs'])) {
      return VoiceIntentType.sale;
    }
    return VoiceIntentType.unknown;
  }

  String? _extractParty(String text) {
    final koMatch = RegExp(r'^(.+?)\s+(ko|se)\s+').firstMatch(text);
    if (koMatch != null) {
      return _titleCase(koMatch.group(1)!.trim());
    }
    final partyMatch = RegExp(r'(.+?)\s+(ko|se)\s+\d').firstMatch(text);
    if (partyMatch != null) {
      return _titleCase(partyMatch.group(1)!.trim());
    }
    return null;
  }

  _ItemBlock _extractItemBlock(String text) {
    final qtyItem = RegExp(
      r'(\d+(?:\.\d+)?)\s*(kilo|kg|kilogram|gram|g|piece|pcs|pc|dozen|box|bori|quintal|ltr|liter|litre)?\s+([a-zA-Z\u0900-\u097F]+)',
    ).firstMatch(text);

    double? quantity;
    String? unit;
    String? itemName;
    double? rate;

    if (qtyItem != null) {
      quantity = double.tryParse(qtyItem.group(1)!);
      unit = _normalizeUnit(qtyItem.group(2));
      itemName = _titleCase(qtyItem.group(3)!);
    }

    final perKilo = RegExp(
      r'(\d+(?:\.\d+)?)\s+(?:rupaye|rupya|rs|rupees)\s+(?:per\s+)?(?:kilo|kg|kilogram)',
    ).firstMatch(text);
    if (perKilo != null) {
      rate = double.tryParse(perKilo.group(1)!);
    } else {
      final rateMatch = RegExp(
        r'(\d+(?:\.\d+)?)\s*(?:rupaye|rupya|rs|rupees)\s*(?:per\s+)?(?:kilo|kg|kilogram|piece|pcs|pc)?',
      ).allMatches(text);

      for (final match in rateMatch) {
        final value = double.tryParse(match.group(1)!);
        if (value == null) continue;
        if (quantity != null && value == quantity) continue;
        if (value > 0 && value < 100000) {
          rate = value;
          break;
        }
      }
    }

    return _ItemBlock(
      quantity: quantity,
      unit: unit,
      itemName: itemName,
      rate: rate,
    );
  }

  PaymentBreakdown _extractPayments(String text) {
    var cash = 0.0;
    var upi = 0.0;
    var bank = 0.0;

    for (final match in RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:rupaye|rupya|rs|rupees)?\s*(?:ka\s+)?(?:cash|nakd|cash mil gaye|cash mile|cash mila|cash mil gaya)',
    ).allMatches(text)) {
      cash += double.tryParse(match.group(1)!) ?? 0;
    }

    for (final match in RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:rupaye|rupya|rs|rupees)?\s*(?:ka\s+)?(?:upi|u p i)',
    ).allMatches(text)) {
      upi += double.tryParse(match.group(1)!) ?? 0;
    }

    for (final match in RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:rupaye|rupya|rs|rupees)?\s*(?:ka\s+)?(?:bank|bank transfer|neft|rtgs|cheque|check)',
    ).allMatches(text)) {
      bank += double.tryParse(match.group(1)!) ?? 0;
    }

    if (cash == 0 && upi == 0 && bank == 0) {
      final simpleCash = RegExp(
        r'(\d+(?:\.\d+)?)\s*(?:rupaye|rupya|rs|rupees)\s*(?:cash|mile|mila|mil gaye|mil gaya)',
      ).firstMatch(text);
      if (simpleCash != null) {
        cash = double.tryParse(simpleCash.group(1)!) ?? 0;
      }
    }

    return PaymentBreakdown(cash: cash, upi: upi, bank: bank);
  }

  List<double> _extractStandaloneAmounts(String text) {
    final amounts = <double>[];
    for (final match in RegExp(r'(\d+(?:\.\d+)?)\s*(?:rupaye|rupya|rs|rupees)').allMatches(text)) {
      final value = double.tryParse(match.group(1)!);
      if (value != null && value > 0) {
        amounts.add(value);
      }
    }
    if (amounts.isEmpty) {
      final lone = RegExp(r'\b(\d{2,7})\b').firstMatch(text);
      if (lone != null) {
        final value = double.tryParse(lone.group(1)!);
        if (value != null) amounts.add(value);
      }
    }
    return amounts;
  }

  DateTime? _extractReminderDate(String text, DateTime reference) {
    if (!_hasAny(text, ['reminder', 'yaad', 'yaad dilana', 'yaad dilao'])) {
      final hasMonth = _monthNames.keys.any(text.contains);
      if (!hasMonth) return null;
    }

    final match = RegExp(
      r'(\d{1,2})\s*(jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y|ai)?|aug(?:ust)?|sep(?:t(?:ember)?)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)',
    ).firstMatch(text);

    if (match == null) return null;

    final day = int.tryParse(match.group(1)!);
    final month = _monthNames[match.group(2)!];
    if (day == null || month == null) return null;

    var year = reference.year;
    final candidate = DateTime(year, month, day);
    if (candidate.isBefore(DateTime(reference.year, reference.month, reference.day))) {
      year += 1;
    }
    return DateTime(year, month, day);
  }

  String? _extractExpenseName(String text) {
    final kaMatch = RegExp(r'(\d+(?:\.\d+)?)\s*(?:rupaye|rupya|rs)?\s*(?:ka|ki|ke)\s+([a-zA-Z\u0900-\u097F]+)').firstMatch(text);
    if (kaMatch != null) {
      return _titleCase(kaMatch.group(2)!);
    }
    final beforeKharch = RegExp(r'([a-zA-Z\u0900-\u097F]+)\s+(?:ka|ki|ke)?\s*(?:kharch|kharcha)').firstMatch(text);
    if (beforeKharch != null) {
      return _titleCase(beforeKharch.group(1)!);
    }
    return null;
  }

  String? _extractCreatePartyName(String text) {
    final match = RegExp(r'(.+?)\s+(?:naam ki party|party banao|nayi party)').firstMatch(text);
    if (match != null) {
      return _titleCase(match.group(1)!);
    }
    return null;
  }

  String? _normalizeUnit(String? raw) {
    if (raw == null || raw.isEmpty) return 'Kg';
    final value = raw.toLowerCase();
    if (value.startsWith('kilo') || value == 'kg') return 'Kg';
    if (value.startsWith('gram') || value == 'g') return 'Gram';
    if (value.startsWith('piece') || value == 'pcs' || value == 'pc') return 'Pcs';
    if (value == 'dozen') return 'Dozen';
    if (value == 'box') return 'Box';
    if (value == 'bori') return 'Bori';
    if (value.startsWith('ltr') || value.startsWith('lit')) return 'Ltr';
    return _titleCase(raw);
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value.split(' ').map((part) {
      if (part.isEmpty) return part;
      return part[0].toUpperCase() + part.substring(1);
    }).join(' ');
  }

  bool _hasAny(String text, List<String> needles) {
    return needles.any(text.contains);
  }

  static const _monthNames = {
    'jan': 1,
    'january': 1,
    'feb': 2,
    'february': 2,
    'mar': 3,
    'march': 3,
    'apr': 4,
    'april': 4,
    'may': 5,
    'jun': 6,
    'june': 6,
    'jul': 7,
    'july': 7,
    'julai': 7,
    'aug': 8,
    'august': 8,
    'sep': 9,
    'sept': 9,
    'september': 9,
    'oct': 10,
    'october': 10,
    'nov': 11,
    'november': 11,
    'dec': 12,
    'december': 12,
  };
}

class _ItemBlock {
  const _ItemBlock({
    this.quantity,
    this.unit,
    this.itemName,
    this.rate,
  });

  final double? quantity;
  final String? unit;
  final String? itemName;
  final double? rate;
}

/// Applies a clarification answer onto a partial draft.
VoiceDraft applyClarificationAnswer(
  VoiceDraft draft,
  VoiceClarification clarification,
  String answer,
) {
  final trimmed = answer.trim();
  switch (clarification.field) {
    case VoiceClarificationField.intent:
      final lower = trimmed.toLowerCase();
      VoiceIntentType intent = VoiceIntentType.unknown;
      if (lower.contains('bikri') || lower.contains('sale')) {
        intent = VoiceIntentType.sale;
      } else if (lower.contains('kharid') || lower.contains('purchase')) {
        intent = VoiceIntentType.purchase;
      } else if (lower.contains('mila') || lower.contains('mile') || lower.contains('jama')) {
        intent = VoiceIntentType.paymentReceived;
      } else if (lower.contains('diya') || lower.contains('diye')) {
        intent = VoiceIntentType.paymentPaid;
      } else if (lower.contains('kharch')) {
        intent = VoiceIntentType.expense;
      } else if (lower.contains('party')) {
        intent = VoiceIntentType.createParty;
      } else if (lower.contains('maal') || lower.contains('item')) {
        intent = VoiceIntentType.createItem;
      }
      return draft.copyWith(intent: intent);
    case VoiceClarificationField.party:
      return draft.copyWith(partyName: trimmed);
    case VoiceClarificationField.item:
      return draft.copyWith(itemName: trimmed);
    case VoiceClarificationField.quantity:
      return draft.copyWith(quantity: double.tryParse(trimmed.replaceAll(RegExp(r'[^0-9.]'), '')));
    case VoiceClarificationField.unit:
      return draft.copyWith(unit: trimmed);
    case VoiceClarificationField.rate:
      return draft.copyWith(rate: double.tryParse(trimmed.replaceAll(RegExp(r'[^0-9.]'), '')));
    case VoiceClarificationField.amount:
      return draft.copyWith(amount: double.tryParse(trimmed.replaceAll(RegExp(r'[^0-9.]'), '')));
    case VoiceClarificationField.expenseName:
      return draft.copyWith(expenseName: trimmed);
  }
}

/// Re-validate draft after clarification answer.
VoiceParseResult revalidateVoiceDraft(VoiceDraft draft, RuleVoiceParser parser) {
  return parser.revalidate(draft);
}
