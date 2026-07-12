import '../../../core/accounting/payment_breakdown.dart';
import 'voice_intent_type.dart';
import 'voice_memory.dart';

/// Field that needs user clarification before preview.
enum VoiceClarificationField {
  intent,
  party,
  item,
  quantity,
  unit,
  rate,
  amount,
  expenseName,
  reminderDate,
}

/// One clarifying question from the parser — never guess missing data.
class VoiceClarification {
  const VoiceClarification({
    required this.question,
    required this.field,
  });

  final String question;
  final VoiceClarificationField field;
}

/// Parsed voice command ready for entity resolution and preview.
class VoiceDraft {
  const VoiceDraft({
    required this.intent,
    required this.rawText,
    this.partyName,
    this.itemName,
    this.unit,
    this.quantity,
    this.rate,
    this.amount,
    this.paymentBreakdown = const PaymentBreakdown(),
    this.reminderDate,
    this.notes,
    this.expenseName,
  });

  final VoiceIntentType intent;
  final String rawText;
  final String? partyName;
  final String? itemName;
  final String? unit;
  final double? quantity;
  final double? rate;
  final double? amount;
  final PaymentBreakdown paymentBreakdown;
  final DateTime? reminderDate;
  final String? notes;
  final String? expenseName;

  double get lineTotal {
    if (quantity != null && rate != null) {
      return quantity! * rate!;
    }
    return amount ?? 0;
  }

  double get creditAmount {
    final total = lineTotal;
    if (total <= 0) return 0;
    return paymentBreakdown.remainingCredit(total);
  }

  VoiceDraft copyWith({
    VoiceIntentType? intent,
    String? rawText,
    String? partyName,
    String? itemName,
    String? unit,
    double? quantity,
    double? rate,
    double? amount,
    PaymentBreakdown? paymentBreakdown,
    DateTime? reminderDate,
    String? notes,
    String? expenseName,
    bool clearReminderDate = false,
  }) {
    return VoiceDraft(
      intent: intent ?? this.intent,
      rawText: rawText ?? this.rawText,
      partyName: partyName ?? this.partyName,
      itemName: itemName ?? this.itemName,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      rate: rate ?? this.rate,
      amount: amount ?? this.amount,
      paymentBreakdown: paymentBreakdown ?? this.paymentBreakdown,
      reminderDate: clearReminderDate ? null : (reminderDate ?? this.reminderDate),
      notes: notes ?? this.notes,
      expenseName: expenseName ?? this.expenseName,
    );
  }
}

/// Parser output — success or one clarification at a time.
class VoiceParseResult {
  const VoiceParseResult({
    required this.draft,
    this.clarification,
  });

  final VoiceDraft draft;
  final VoiceClarification? clarification;

  bool get needsClarification => clarification != null;
}

/// Resolved draft with database IDs for preview and save.
class VoiceResolvedDraft {
  const VoiceResolvedDraft({
    required this.draft,
    this.partyId,
    this.itemId,
    this.createParty = false,
    this.createItem = false,
    this.confidence = const {},
    this.memoryUsed = false,
  });

  final VoiceDraft draft;
  final String? partyId;
  final String? itemId;
  final bool createParty;
  final bool createItem;
  final Map<VoiceConfidenceField, VoiceConfidenceLevel> confidence;
  final bool memoryUsed;

  VoiceResolvedDraft copyWith({
    VoiceDraft? draft,
    String? partyId,
    String? itemId,
    bool? createParty,
    bool? createItem,
    Map<VoiceConfidenceField, VoiceConfidenceLevel>? confidence,
    bool? memoryUsed,
  }) {
    return VoiceResolvedDraft(
      draft: draft ?? this.draft,
      partyId: partyId ?? this.partyId,
      itemId: itemId ?? this.itemId,
      createParty: createParty ?? this.createParty,
      createItem: createItem ?? this.createItem,
      confidence: confidence ?? this.confidence,
      memoryUsed: memoryUsed ?? this.memoryUsed,
    );
  }
}
