import '../domain/voice_draft.dart';
import '../domain/voice_intent_type.dart';
import '../domain/voice_memory.dart';

/// Preview model — all fields the mandatory preview screen must show.
class VoicePreviewModel {
  const VoicePreviewModel({
    required this.resolved,
    required this.lineTotal,
    required this.creditAmount,
    required this.showParty,
    required this.showItem,
    required this.showAmountOnly,
    required this.showPaymentSplit,
  });

  final VoiceResolvedDraft resolved;
  final double lineTotal;
  final double creditAmount;
  final bool showParty;
  final bool showItem;
  final bool showAmountOnly;
  final bool showPaymentSplit;

  VoiceDraft get draft => resolved.draft;
  Map<VoiceConfidenceField, VoiceConfidenceLevel> get confidence => resolved.confidence;
  bool get memoryUsed => resolved.memoryUsed;
}

/// Builds preview-ready models from parsed voice results.
abstract final class PreviewGenerator {
  static VoicePreviewModel fromResolved(VoiceResolvedDraft resolved) {
    final draft = resolved.draft;
    final total = draft.lineTotal;
    final credit = draft.creditAmount;

    return VoicePreviewModel(
      resolved: resolved,
      lineTotal: total,
      creditAmount: credit,
      showParty: _showParty(draft.intent),
      showItem: _showItem(draft.intent) || draft.intent == VoiceIntentType.createItem,
      showAmountOnly: _showAmountOnly(draft.intent),
      showPaymentSplit: _showPaymentSplit(draft.intent),
    );
  }

  static bool _showParty(VoiceIntentType intent) {
    return switch (intent) {
      VoiceIntentType.sale ||
      VoiceIntentType.purchase ||
      VoiceIntentType.paymentReceived ||
      VoiceIntentType.paymentPaid ||
      VoiceIntentType.createParty ||
      VoiceIntentType.reminder =>
        true,
      _ => false,
    };
  }

  static bool _showItem(VoiceIntentType intent) {
    return intent == VoiceIntentType.sale || intent == VoiceIntentType.purchase;
  }

  static bool _showAmountOnly(VoiceIntentType intent) {
    return intent == VoiceIntentType.paymentReceived ||
        intent == VoiceIntentType.paymentPaid ||
        intent == VoiceIntentType.expense ||
        intent == VoiceIntentType.reminder;
  }

  static bool _showPaymentSplit(VoiceIntentType intent) {
    return intent == VoiceIntentType.sale ||
        intent == VoiceIntentType.purchase ||
        intent == VoiceIntentType.paymentReceived ||
        intent == VoiceIntentType.paymentPaid;
  }
}
