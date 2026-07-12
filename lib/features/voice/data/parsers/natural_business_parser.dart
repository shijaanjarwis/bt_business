import '../../../../core/accounting/payment_breakdown.dart';
import '../../domain/voice_intent_type.dart';

/// Natural Hindi/English shopkeeper phrase extraction — Phase 2.
abstract final class NaturalBusinessParser {
  static String normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('₹', ' rupaye ')
        .replaceAll(RegExp(r'[^\w\s\u0900-\u097F.]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static VoiceIntentType detectIntent(String text) {
    if (_hasAny(text, ['party banao', 'naam ki party', 'nayi party', 'new party'])) {
      return VoiceIntentType.createParty;
    }
    if (_hasAny(text, ['maal banao', 'item banao', 'naya maal', 'new item'])) {
      return VoiceIntentType.createItem;
    }
    if (_hasAny(text, ['yaad dilana', 'yaad dilao', 'yaad rakh', 'payment yaad', 'reminder'])) {
      if (!_hasAny(text, ['bech', 'beche', 'becha', 'bikri', 'kharid', 'kharide', 'mile', 'mila'])) {
        return VoiceIntentType.reminder;
      }
    }
    if (_hasAny(text, ['kharch', 'kharcha', 'expense', 'likho'])) {
      if (!_hasAny(text, ['bech', 'beche', 'bikri', 'kharid'])) {
        return VoiceIntentType.expense;
      }
    }
    if (_hasAny(text, ['kharid', 'kharidi', 'kharida', 'kharide', 'purchase', 'liya', 'liye', 'manga'])) {
      return VoiceIntentType.purchase;
    }
    if (_hasAny(text, ['bechi', 'beche', 'becha', 'bikri', 'sale', 'sold', 'bech di', 'bech diya'])) {
      return VoiceIntentType.sale;
    }
    if (_hasAny(text, ['mile', 'mila', 'mil gaye', 'mil gaya', 'jama', 'received', 'receive'])) {
      if (!_hasAny(text, ['bechi', 'beche', 'becha', 'bikri', 'sale', 'kharid', 'kharide'])) {
        return VoiceIntentType.paymentReceived;
      }
    }
    if (_hasAny(text, ['diye', 'diya', 'de diye', 'de diya', 'paid to'])) {
      return VoiceIntentType.paymentPaid;
    }
    if (_hasAny(text, ['udhaar di', 'udhar di'])) {
      if (RegExp(r'\d+\s*(kilo|kg|piece|pcs|box)').hasMatch(text)) {
        return VoiceIntentType.sale;
      }
      return VoiceIntentType.paymentPaid;
    }
    if (_hasAny(text, ['bhej do', 'bhejo', 'aur bhej', 'aur bhejo'])) {
      return VoiceIntentType.sale;
    }
    if (text.contains(' ko ') && _hasAny(text, ['kilo', 'kg', 'piece', 'pcs', 'box', 'aur'])) {
      return VoiceIntentType.sale;
    }
    return VoiceIntentType.unknown;
  }

  static String? extractParty(String text) {
    final koMatch = RegExp(r'^(.+?)\s+(ko|se)\s+').firstMatch(text);
    if (koMatch != null) {
      return _titleCase(_cleanPartyToken(koMatch.group(1)!));
    }
    final inlineKo = RegExp(r'\b([a-z\u0900-\u097F]+)\s+ko\s+').firstMatch(text);
    if (inlineKo != null) {
      return _titleCase(inlineKo.group(1)!);
    }
    final partyMatch = RegExp(r'(.+?)\s+(ko|se)\s+\d').firstMatch(text);
    if (partyMatch != null) {
      return _titleCase(_cleanPartyToken(partyMatch.group(1)!));
    }
    return null;
  }

  static ItemParseResult extractItemBlock(String text) {
    double? quantity;
    String? unit;
    String? itemName;
    double? rate;

    final qtyUnitItem = RegExp(
      r'(\d+(?:\.\d+)?)\s*(kilo|kg|kilogram|gram|g|piece|pieces|pc|pcs|dozen|box|boxes|bori|quintal|ltr|liter|litre)\s+(.+?)(?:\s+\d|\s+(?:rupaye|rupya|rs|cash|udhaar|udhar|beche|becha|bechi|kharid|kharide|mile|mila|diya|diye)|$)',
    ).firstMatch(text);

    if (qtyUnitItem != null) {
      quantity = double.tryParse(qtyUnitItem.group(1)!);
      unit = normalizeUnit(qtyUnitItem.group(2));
      itemName = _cleanItemName(qtyUnitItem.group(3)!.trim());
    }

    final perUnitRate = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:rupaye|rupya|rs|rupees)\s+(?:per\s+)?(?:kilo|kg|kilogram|piece|pcs|pc|box|boxes)',
    ).firstMatch(text);
    if (perUnitRate != null) {
      rate = double.tryParse(perUnitRate.group(1)!);
    } else {
      for (final match in RegExp(
        r'(\d+(?:\.\d+)?)\s*(?:rupaye|rupya|rs|rupees)(?:\s+(?:per\s+)?(?:kilo|kg|kilogram|piece|pcs|pc|box|boxes))?',
      ).allMatches(text)) {
        final value = double.tryParse(match.group(1)!);
        if (value == null) continue;
        if (quantity != null && value == quantity) continue;
        if (value > 0 && value <= 999999) {
          rate = value;
          break;
        }
      }
    }

    return ItemParseResult(
      quantity: quantity,
      unit: unit,
      itemName: itemName,
      rate: rate,
    );
  }

  static PaymentBreakdown extractPayments(String text) {
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
      r'(\d+(?:\.\d+)?)\s*(?:rupaye|rupya|rs|rupees)?\s*(?:ka\s+)?(?:bank|bank se|bank transfer|neft|rtgs|cheque|check)',
    ).allMatches(text)) {
      bank += double.tryParse(match.group(1)!) ?? 0;
    }

    if (cash == 0 && upi == 0 && bank == 0) {
      final cashMila = RegExp(
        r'(\d+(?:\.\d+)?)\s*(?:rupaye|rupya|rs|rupees)?\s*(?:cash\s+)?(?:mile|mila|mil gaye|mil gaya)',
      ).firstMatch(text);
      if (cashMila != null) {
        cash = double.tryParse(cashMila.group(1)!) ?? 0;
      }
    }

    return PaymentBreakdown(cash: cash, upi: upi, bank: bank);
  }

  static List<double> extractStandaloneAmounts(String text) {
    final amounts = <double>[];
    for (final match in RegExp(r'(\d+(?:\.\d+)?)\s*(?:rupaye|rupya|rs|rupees)').allMatches(text)) {
      final value = double.tryParse(match.group(1)!);
      if (value != null && value > 0) amounts.add(value);
    }
    if (amounts.isEmpty) {
      final kharchAmount = RegExp(r'(\d+(?:\.\d+)?)\s+(?:kharch|kharcha)').firstMatch(text);
      if (kharchAmount != null) {
        final value = double.tryParse(kharchAmount.group(1)!);
        if (value != null) amounts.add(value);
      }
    }
    if (amounts.isEmpty) {
      final bankOrCash = RegExp(r'\b(\d{2,7})\b\s+(?:cash|bank)\s+(?:mile|mila|se)').firstMatch(text);
      if (bankOrCash != null) {
        final value = double.tryParse(bankOrCash.group(1)!);
        if (value != null) amounts.add(value);
      }
    }
    if (amounts.isEmpty) {
      final kaKharch = RegExp(r'(\d+(?:\.\d+)?)\s+(?:ka|ki|ke)\s+\w+\s+(?:kharch|kharcha)').firstMatch(text);
      if (kaKharch != null) {
        final value = double.tryParse(kaKharch.group(1)!);
        if (value != null) amounts.add(value);
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

  static ReminderParseResult extractReminder(String text, DateTime reference) {
    var date = _extractCalendarDate(text, reference);
    date ??= _extractRelativeDate(text, reference);
    final timeLabel = _extractTimeLabel(text);
    return ReminderParseResult(date: date, timeLabel: timeLabel);
  }

  static String? extractExpenseName(String text) {
    final amountKa = RegExp(
      r'([a-zA-Z\u0900-\u097F]+)\s+(?:ka|ki|ke)\s+\d+(?:\.\d+)?\s+(?:kharch|kharcha)',
    ).firstMatch(text);
    if (amountKa != null) return _titleCase(amountKa.group(1)!);
    final kaMatch = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:rupaye|rupya|rs)?\s*(?:ka|ki|ke)\s+([a-zA-Z\u0900-\u097F]+)',
    ).firstMatch(text);
    if (kaMatch != null) return _titleCase(kaMatch.group(2)!);
    final beforeKharch = RegExp(
      r'([a-zA-Z\u0900-\u097F]+)\s+(?:ka|ki|ke)?\s*(?:kharch|kharcha)',
    ).firstMatch(text);
    if (beforeKharch != null) return _titleCase(beforeKharch.group(1)!);
    return null;
  }

  static String? extractCreatePartyName(String text) {
    final match = RegExp(r'(.+?)\s+(?:naam ki party|party banao|nayi party)').firstMatch(text);
    if (match != null) return _titleCase(match.group(1)!);
    return null;
  }

  static String? normalizeUnit(String? raw) {
    if (raw == null || raw.isEmpty) return 'Kg';
    final value = raw.toLowerCase();
    if (value.startsWith('kilo') || value == 'kg') return 'Kg';
    if (value.startsWith('gram') || value == 'g') return 'Gram';
    if (value.startsWith('piece') || value == 'pcs' || value == 'pc') return 'Pcs';
    if (value == 'dozen') return 'Dozen';
    if (value.startsWith('box')) return 'Box';
    if (value == 'bori') return 'Bori';
    if (value.startsWith('ltr') || value.startsWith('lit')) return 'Ltr';
    return _titleCase(raw);
  }

  static DateTime? _extractCalendarDate(String text, DateTime reference) {
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

  static DateTime? _extractRelativeDate(String text, DateTime reference) {
    final today = DateTime(reference.year, reference.month, reference.day);
    if (_hasAny(text, ['aaj ', ' aaj'])) return today;
    if (_hasAny(text, ['kal ', ' kal'])) return today.add(const Duration(days: 1));
    if (_hasAny(text, ['parso', 'parso '])) return today.add(const Duration(days: 2));
    return null;
  }

  static String? _extractTimeLabel(String text) {
    final clock = RegExp(r'(\d{1,2})\s*baje').firstMatch(text);
    if (clock != null) {
      final hour = clock.group(1);
      if (_hasAny(text, ['shaam', 'sham', 'evening'])) return 'Shaam $hour baje';
      if (_hasAny(text, ['subah', 'morning'])) return 'Subah $hour baje';
      if (_hasAny(text, ['dopahar', 'afternoon'])) return 'Dopahar $hour baje';
      return '$hour baje';
    }
    if (_hasAny(text, ['shaam', 'sham', 'evening'])) return 'Shaam';
    if (_hasAny(text, ['subah', 'morning'])) return 'Subah';
    if (_hasAny(text, ['dopahar', 'afternoon'])) return 'Dopahar';
    return null;
  }

  static String _cleanPartyToken(String raw) {
    return raw
        .replaceAll(RegExp(r'\b(aaj|kal|parso|shaam|sham|subah|dopahar)\b'), '')
        .replaceAll(RegExp(r'\b\d{1,2}\s*baje\b'), '')
        .trim();
  }

  static String? _cleanItemName(String raw) {
    var value = raw
        .replaceAll(RegExp(r'\b(cash|udhaar|udhar|beche|becha|bechi|kharid|kharide|mile|mila)\b'), '')
        .replaceAll(RegExp(r'\b(sale|kiya|kiya hai|kharida|kharidi)\b'), '')
        .replaceAll(RegExp(r'\b\d+\s*(?:rupaye|rupya|rs|rupees)\b'), '')
        .trim();
    if (value.isEmpty || _isNoiseToken(value)) return null;
    return _titleCase(value);
  }

  static bool _isNoiseToken(String value) {
    const noise = {
      'aur', 'bhej', 'bhejo', 'do', 'mil', 'gaye', 'mila', 'mile', 'reminder', 'payment', 'ka', 'ki', 'ke',
    };
    return noise.contains(value.toLowerCase());
  }

  static String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value.split(' ').where((part) => part.isNotEmpty).map((part) {
      return part[0].toUpperCase() + part.substring(1);
    }).join(' ');
  }

  static bool _hasAny(String text, List<String> needles) => needles.any(text.contains);

  static const _monthNames = {
    'jan': 1, 'january': 1, 'feb': 2, 'february': 2, 'mar': 3, 'march': 3,
    'apr': 4, 'april': 4, 'may': 5, 'jun': 6, 'june': 6, 'jul': 7, 'july': 7,
    'julai': 7, 'aug': 8, 'august': 8, 'sep': 9, 'sept': 9, 'september': 9,
    'oct': 10, 'october': 10, 'nov': 11, 'november': 11, 'dec': 12, 'december': 12,
  };
}

class ItemParseResult {
  const ItemParseResult({this.quantity, this.unit, this.itemName, this.rate});
  final double? quantity;
  final String? unit;
  final String? itemName;
  final double? rate;
}

class ReminderParseResult {
  const ReminderParseResult({this.date, this.timeLabel});
  final DateTime? date;
  final String? timeLabel;
}
