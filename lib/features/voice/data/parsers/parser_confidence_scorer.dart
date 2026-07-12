import '../../domain/voice_draft.dart';
import '../../domain/voice_intent_type.dart';
import '../../domain/voice_memory.dart';

/// Computes parser-level confidence (0–100) for preview highlighting.
abstract final class ParserConfidenceScorer {
  static const double previewThreshold = 0.90;

  static ConfidenceScore score(VoiceDraft draft) {
    final fields = <VoiceConfidenceField, VoiceConfidenceLevel>{};
    final weights = <VoiceConfidenceField, double>{};

    void mark(VoiceConfidenceField field, bool present, {bool explicit = true}) {
      weights[field] = 1;
      if (!present) {
        fields[field] = VoiceConfidenceLevel.low;
        return;
      }
      fields[field] = explicit ? VoiceConfidenceLevel.high : VoiceConfidenceLevel.medium;
    }

    switch (draft.intent) {
      case VoiceIntentType.sale:
      case VoiceIntentType.purchase:
        mark(VoiceConfidenceField.party, _hasText(draft.partyName));
        mark(VoiceConfidenceField.item, _hasText(draft.itemName));
        mark(VoiceConfidenceField.quantity, draft.quantity != null && draft.quantity! > 0);
        mark(VoiceConfidenceField.unit, _hasText(draft.unit));
        mark(VoiceConfidenceField.rate, draft.rate != null && draft.rate! > 0);
        if (draft.paymentBreakdown.cash > 0) {
          mark(VoiceConfidenceField.cash, true);
        }
        if (draft.paymentBreakdown.upi > 0) {
          mark(VoiceConfidenceField.upi, true);
        }
        if (draft.paymentBreakdown.bank > 0) {
          mark(VoiceConfidenceField.bank, true);
        }
        if (draft.creditAmount > 0) {
          mark(VoiceConfidenceField.credit, true);
        }
        if (draft.reminderDate != null) {
          mark(VoiceConfidenceField.reminder, true);
        }
      case VoiceIntentType.paymentReceived:
      case VoiceIntentType.paymentPaid:
        mark(VoiceConfidenceField.party, _hasText(draft.partyName));
        mark(
          VoiceConfidenceField.amount,
          (draft.amount ?? 0) > 0 || draft.paymentBreakdown.paidTotal > 0,
        );
        if (draft.paymentBreakdown.cash > 0) mark(VoiceConfidenceField.cash, true);
        if (draft.paymentBreakdown.upi > 0) mark(VoiceConfidenceField.upi, true);
        if (draft.paymentBreakdown.bank > 0) mark(VoiceConfidenceField.bank, true);
        if (draft.reminderDate != null) mark(VoiceConfidenceField.reminder, true);
      case VoiceIntentType.expense:
        mark(VoiceConfidenceField.item, _hasText(draft.expenseName));
        mark(VoiceConfidenceField.amount, (draft.amount ?? 0) > 0);
      case VoiceIntentType.createParty:
        mark(VoiceConfidenceField.party, _hasText(draft.partyName));
      case VoiceIntentType.createItem:
        mark(VoiceConfidenceField.item, _hasText(draft.itemName));
        mark(VoiceConfidenceField.unit, _hasText(draft.unit));
      case VoiceIntentType.reminder:
        mark(VoiceConfidenceField.party, _hasText(draft.partyName));
        mark(VoiceConfidenceField.reminder, draft.reminderDate != null);
        mark(VoiceConfidenceField.amount, (draft.amount ?? 0) > 0, explicit: false);
      case VoiceIntentType.unknown:
        mark(VoiceConfidenceField.party, false);
    }

    if (weights.isEmpty) {
      return ConfidenceScore(overall: 0, fields: fields);
    }

    var earned = 0.0;
    for (final entry in weights.entries) {
      final level = fields[entry.key];
      earned += switch (level) {
        VoiceConfidenceLevel.high => 1.0,
        VoiceConfidenceLevel.medium => 0.75,
        VoiceConfidenceLevel.low => 0.25,
        null => 0.0,
      };
    }

    final overall = earned / weights.length;
    return ConfidenceScore(overall: overall, fields: fields);
  }

  static bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
}

class ConfidenceScore {
  const ConfidenceScore({required this.overall, required this.fields});

  final double overall;
  final Map<VoiceConfidenceField, VoiceConfidenceLevel> fields;

  bool get needsCarefulReview => overall < ParserConfidenceScorer.previewThreshold;

  /// Merge parser confidence with memory confidence — lower wins for same field.
  Map<VoiceConfidenceField, VoiceConfidenceLevel> mergeWith(
    Map<VoiceConfidenceField, VoiceConfidenceLevel> memory,
  ) {
    final merged = Map<VoiceConfidenceField, VoiceConfidenceLevel>.from(fields);
    for (final entry in memory.entries) {
      final existing = merged[entry.key];
      if (existing == null) {
        merged[entry.key] = entry.value;
      } else {
        merged[entry.key] = _lower(existing, entry.value);
      }
    }
    if (needsCarefulReview) {
      for (final key in merged.keys.toList()) {
        if (merged[key] != VoiceConfidenceLevel.high) {
          merged[key] = VoiceConfidenceLevel.low;
        }
      }
    }
    return merged;
  }

  static VoiceConfidenceLevel _lower(
    VoiceConfidenceLevel a,
    VoiceConfidenceLevel b,
  ) {
    const order = {
      VoiceConfidenceLevel.high: 0,
      VoiceConfidenceLevel.medium: 1,
      VoiceConfidenceLevel.low: 2,
    };
    return order[a]! >= order[b]! ? a : b;
  }
}
