import 'natural_business_parser.dart';
import '../../domain/voice_draft.dart';
import '../../domain/voice_intent_type.dart';
import '../../domain/voice_parser_interface.dart';

/// Rule-based Hindi/English shopkeeper business parser — Phase 2 natural language.
final class BusinessParser implements VoiceParserInterface {
  @override
  VoiceParseResult parse(String text, {DateTime? referenceDate}) {
    final normalized = NaturalBusinessParser.normalize(text);
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
    final intent = NaturalBusinessParser.detectIntent(normalized);
    final party = NaturalBusinessParser.extractParty(normalized);
    final itemInfo = NaturalBusinessParser.extractItemBlock(normalized);
    final payments = NaturalBusinessParser.extractPayments(normalized);
    final reminder = NaturalBusinessParser.extractReminder(normalized, reference);
    final amounts = NaturalBusinessParser.extractStandaloneAmounts(normalized);

    var notes = reminder.timeLabel;
    if (normalized.contains('aaj ') && intent == VoiceIntentType.expense) {
      notes = notes == null ? 'Aaj' : 'Aaj · $notes';
    }

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
      reminderDate: reminder.date,
      reminderTime: reminder.timeLabel,
      notes: notes,
    );

    draft = _applyIntentDefaults(draft, normalized);
    final clarification = _validateDraft(draft);
    return VoiceParseResult(draft: draft, clarification: clarification);
  }

  VoiceDraft _applyIntentDefaults(VoiceDraft draft, String normalized) {
    switch (draft.intent) {
      case VoiceIntentType.expense:
        final name = draft.expenseName ??
            NaturalBusinessParser.extractExpenseName(normalized) ??
            draft.itemName;
        return draft.copyWith(expenseName: name, itemName: null);
      case VoiceIntentType.createParty:
        final name = draft.partyName ?? NaturalBusinessParser.extractCreatePartyName(normalized);
        return draft.copyWith(partyName: name);
      case VoiceIntentType.paymentReceived:
      case VoiceIntentType.paymentPaid:
        if (draft.amount == null && draft.paymentBreakdown.paidTotal > 0) {
          return draft.copyWith(amount: draft.paymentBreakdown.paidTotal);
        }
        return draft;
      case VoiceIntentType.reminder:
        final note = draft.notes ?? 'Payment yaad dilana';
        return draft.copyWith(notes: note);
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
            question: 'Kitna?',
            field: VoiceClarificationField.quantity,
          );
        }
        if (draft.rate == null || draft.rate! <= 0) {
          return const VoiceClarification(
            question: 'Kitne rate se?',
            field: VoiceClarificationField.rate,
          );
        }
        return _reminderClarificationIfNeeded(draft, null);
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
      case VoiceIntentType.reminder:
        if (draft.partyName == null || draft.partyName!.trim().isEmpty) {
          return const VoiceClarification(
            question: 'Kis party ko yaad dilana hai?',
            field: VoiceClarificationField.party,
          );
        }
        if (draft.reminderDate == null) {
          return const VoiceClarification(
            question: 'Kaunsi date par yaad dilana hai?',
            field: VoiceClarificationField.reminderDate,
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

  VoiceClarification? _reminderClarificationIfNeeded(
    VoiceDraft draft,
    String? normalized,
  ) {
    final text = normalized ?? draft.rawText.toLowerCase();
    if (_hasAny(text, ['reminder', 'yaad dilana', 'yaad dilao', 'yaad rakh']) &&
        draft.reminderDate == null) {
      return const VoiceClarification(
        question: 'Kaunsi date par reminder lagaayein?',
        field: VoiceClarificationField.reminderDate,
      );
    }
    return null;
  }

  VoiceParseResult revalidate(VoiceDraft draft) {
    return VoiceParseResult(
      draft: draft,
      clarification: _validateDraft(draft),
    );
  }

  bool _hasAny(String text, List<String> needles) => needles.any(text.contains);
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
      } else if (lower.contains('yaad') || lower.contains('reminder')) {
        intent = VoiceIntentType.reminder;
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
    case VoiceClarificationField.reminderDate:
      final day = int.tryParse(trimmed.replaceAll(RegExp(r'[^0-9]'), ''));
      if (day == null) return draft;
      final now = DateTime.now();
      var month = now.month;
      var year = now.year;
      if (day < now.day) {
        month += 1;
        if (month > 12) {
          month = 1;
          year += 1;
        }
      }
      return draft.copyWith(reminderDate: DateTime(year, month, day));
  }
}

/// Backward-compatible alias.
typedef RuleVoiceParser = BusinessParser;

/// Re-validate draft after clarification answer.
VoiceParseResult revalidateVoiceDraft(VoiceDraft draft, BusinessParser parser) {
  return parser.revalidate(draft);
}
