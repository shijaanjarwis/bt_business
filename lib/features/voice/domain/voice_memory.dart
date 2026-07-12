import '../../../core/accounting/payment_breakdown.dart';
import 'voice_draft.dart';
import 'voice_intent_type.dart';

/// Confidence level for a preview field inferred from business memory.
enum VoiceConfidenceLevel {
  high,
  medium,
  low,
}

extension VoiceConfidenceLevelLabels on VoiceConfidenceLevel {
  String get hindiLabel => switch (this) {
        VoiceConfidenceLevel.high => 'Pakka',
        VoiceConfidenceLevel.medium => 'Theek',
        VoiceConfidenceLevel.low => 'Kam',
      };
}

/// Preview fields that can carry a confidence indicator.
enum VoiceConfidenceField {
  party,
  item,
  quantity,
  unit,
  rate,
  amount,
  cash,
  upi,
  bank,
  credit,
  reminder,
  notes,
}

/// One stored business pattern — on-device only, max 50 entries.
class VoiceMemoryPattern {
  const VoiceMemoryPattern({
    required this.id,
    required this.intent,
    this.partyName,
    this.itemName,
    this.unit,
    this.rate,
    this.primaryPaymentChannel,
    this.reminderDay,
    this.notes,
    required this.useCount,
    required this.lastUsedAt,
  });

  final String id;
  final VoiceIntentType intent;
  final String? partyName;
  final String? itemName;
  final String? unit;
  final double? rate;
  final String? primaryPaymentChannel;
  final int? reminderDay;
  final String? notes;
  final int useCount;
  final DateTime lastUsedAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'intent': intent.name,
        'partyName': partyName,
        'itemName': itemName,
        'unit': unit,
        'rate': rate,
        'primaryPaymentChannel': primaryPaymentChannel,
        'reminderDay': reminderDay,
        'notes': notes,
        'useCount': useCount,
        'lastUsedAt': lastUsedAt.toIso8601String(),
      };

  static VoiceMemoryPattern fromJson(Map<String, Object?> json) {
    return VoiceMemoryPattern(
      id: json['id']! as String,
      intent: VoiceIntentType.values.byName(json['intent']! as String),
      partyName: json['partyName'] as String?,
      itemName: json['itemName'] as String?,
      unit: json['unit'] as String?,
      rate: (json['rate'] as num?)?.toDouble(),
      primaryPaymentChannel: json['primaryPaymentChannel'] as String?,
      reminderDay: json['reminderDay'] as int?,
      notes: json['notes'] as String?,
      useCount: json['useCount']! as int,
      lastUsedAt: DateTime.parse(json['lastUsedAt']! as String),
    );
  }

  VoiceMemoryPattern bumpUsage({
    String? unit,
    double? rate,
    String? primaryPaymentChannel,
    int? reminderDay,
    String? notes,
  }) {
    return VoiceMemoryPattern(
      id: id,
      intent: intent,
      partyName: partyName,
      itemName: itemName,
      unit: unit ?? this.unit,
      rate: rate ?? this.rate,
      primaryPaymentChannel: primaryPaymentChannel ?? this.primaryPaymentChannel,
      reminderDay: reminderDay ?? this.reminderDay,
      notes: notes ?? this.notes,
      useCount: useCount + 1,
      lastUsedAt: DateTime.now(),
    );
  }
}

/// Parser output enriched with memory predictions and confidence.
class VoiceEnrichedResult {
  const VoiceEnrichedResult({
    required this.draft,
    required this.confidence,
    this.clarification,
    this.memoryUsed = false,
  });

  final VoiceDraft draft;
  final Map<VoiceConfidenceField, VoiceConfidenceLevel> confidence;
  final VoiceClarification? clarification;
  final bool memoryUsed;

  bool get needsClarification => clarification != null;

  VoiceConfidenceLevel? levelFor(VoiceConfidenceField field) => confidence[field];

  VoiceEnrichedResult copyWith({
    VoiceDraft? draft,
    Map<VoiceConfidenceField, VoiceConfidenceLevel>? confidence,
    VoiceClarification? clarification,
    bool? memoryUsed,
    bool clearClarification = false,
  }) {
    return VoiceEnrichedResult(
      draft: draft ?? this.draft,
      confidence: confidence ?? this.confidence,
      clarification: clearClarification ? null : (clarification ?? this.clarification),
      memoryUsed: memoryUsed ?? this.memoryUsed,
    );
  }
}

/// Builds confidence map from which fields were spoken vs inferred.
VoiceConfidenceLevel confidenceFromUsage({
  required bool spokenInText,
  required int useCount,
  required bool exactPartyItemMatch,
}) {
  if (spokenInText) return VoiceConfidenceLevel.high;
  if (exactPartyItemMatch && useCount >= 3) return VoiceConfidenceLevel.high;
  if (useCount >= 2) return VoiceConfidenceLevel.medium;
  return VoiceConfidenceLevel.low;
}

/// Derives primary payment channel label from breakdown.
String? primaryPaymentChannel(PaymentBreakdown breakdown) {
  if (breakdown.cash >= breakdown.upi && breakdown.cash >= breakdown.bank && breakdown.cash > 0) {
    return 'cash';
  }
  if (breakdown.upi >= breakdown.bank && breakdown.upi > 0) return 'upi';
  if (breakdown.bank > 0) return 'bank';
  return null;
}
