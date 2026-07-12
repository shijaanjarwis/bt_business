import '../data/memory/voice_business_memory_store.dart';
import '../data/parsers/parser_confidence_scorer.dart';
import '../data/parsers/business_parser.dart';
import '../domain/voice_draft.dart';
import '../domain/voice_intent_type.dart';
import '../domain/voice_memory.dart';

/// Smart Business Memory — enriches voice drafts from on-device patterns only.
final class VoiceMemoryEngine {
  VoiceMemoryEngine({
    required VoiceBusinessMemoryStore store,
    BusinessParser? parser,
  })  : _store = store,
        _parser = parser ?? BusinessParser();

  final VoiceBusinessMemoryStore _store;
  final BusinessParser _parser;

  Future<VoiceEnrichedResult> enrich({
    required VoiceParseResult parseResult,
    required String rawText,
  }) async {
    await _store.warmCache();

    var draft = parseResult.draft;
    final normalized = _normalize(rawText);
    final confidence = <VoiceConfidenceField, VoiceConfidenceLevel>{};
    var memoryUsed = false;

    draft = _applyContinuationParsing(draft, normalized);

    if (_wantsSameRate(normalized) &&
        draft.partyName != null &&
        (draft.rate == null || draft.rate! <= 0)) {
      final ctx = _store.findRateFor(
        partyName: draft.partyName!,
        itemName: draft.itemName,
        intent: draft.intent == VoiceIntentType.purchase
            ? VoiceIntentType.purchase
            : VoiceIntentType.sale,
      );
      if (ctx?.rate != null) {
        draft = draft.copyWith(rate: ctx!.rate);
        confidence[VoiceConfidenceField.rate] = confidenceFromUsage(
          spokenInText: false,
          useCount: ctx.useCount,
          exactPartyItemMatch: _same(ctx.itemName, draft.itemName),
        );
        memoryUsed = true;
      }
    }

    if ((draft.intent == VoiceIntentType.sale ||
            draft.intent == VoiceIntentType.purchase) &&
        draft.partyName != null &&
        (draft.itemName == null || draft.itemName!.isEmpty)) {
      final ctx = _store.findPartyItemContext(
        partyName: draft.partyName!,
        intent: draft.intent,
      );
      if (ctx != null && (_isContinuation(normalized) || _mentionsMaalOnly(normalized))) {
        draft = draft.copyWith(
          itemName: ctx.itemName,
          unit: draft.unit ?? ctx.unit,
        );
        confidence[VoiceConfidenceField.item] = confidenceFromUsage(
          spokenInText: false,
          useCount: ctx.useCount,
          exactPartyItemMatch: true,
        );
        if (ctx.unit != null && (draft.unit == null || draft.unit!.isEmpty)) {
          confidence[VoiceConfidenceField.unit] = confidenceFromUsage(
            spokenInText: false,
            useCount: ctx.useCount,
            exactPartyItemMatch: true,
          );
        }
        memoryUsed = true;
      }
    }

    if ((draft.unit == null || draft.unit!.isEmpty) &&
        draft.itemName != null &&
        draft.partyName != null) {
      final ctx = _store.findPartyItemContext(
        partyName: draft.partyName!,
        intent: draft.intent,
      );
      if (ctx?.unit != null && _same(ctx!.itemName, draft.itemName)) {
        draft = draft.copyWith(unit: ctx.unit);
        confidence[VoiceConfidenceField.unit] = confidenceFromUsage(
          spokenInText: false,
          useCount: ctx.useCount,
          exactPartyItemMatch: true,
        );
        memoryUsed = true;
      }
    }

    _markSpokenConfidence(draft, normalized, confidence);

    final parserScore = ParserConfidenceScorer.score(draft);
    final mergedConfidence = parserScore.mergeWith(confidence);

    final clarification = _parser.revalidate(draft).clarification ??
        _reminderClarification(draft, normalized);

    return VoiceEnrichedResult(
      draft: draft,
      confidence: mergedConfidence,
      clarification: clarification,
      memoryUsed: memoryUsed,
      overallConfidence: parserScore.overall,
    );
  }

  Future<void> learnFromSave(VoiceDraft draft) {
    return _store.learnFromDraft(draft);
  }

  VoiceDraft _applyContinuationParsing(VoiceDraft draft, String normalized) {
    var updated = draft;

    if (updated.intent == VoiceIntentType.unknown && _isContinuation(normalized)) {
      updated = updated.copyWith(intent: VoiceIntentType.sale);
    }

    if (_isContinuation(normalized) && updated.quantity == null) {
      final qty = RegExp(r'(\d+(?:\.\d+)?)\s+aur').firstMatch(normalized);
      if (qty != null) {
        updated = updated.copyWith(
          quantity: double.tryParse(qty.group(1)!),
        );
      }
    }

    if (_isContinuation(normalized) &&
        (updated.intent == VoiceIntentType.sale || updated.intent == VoiceIntentType.unknown)) {
      updated = updated.copyWith(intent: VoiceIntentType.sale);
    }

    return updated;
  }

  VoiceClarification? _reminderClarification(VoiceDraft draft, String normalized) {
    if (_hasReminderKeyword(normalized) && draft.reminderDate == null) {
      return const VoiceClarification(
        question: 'Kaunsi date par reminder lagaayein?',
        field: VoiceClarificationField.reminderDate,
      );
    }
    return null;
  }

  void _markSpokenConfidence(
    VoiceDraft draft,
    String normalized,
    Map<VoiceConfidenceField, VoiceConfidenceLevel> confidence,
  ) {
    void mark(VoiceConfidenceField field, bool spoken) {
      if (spoken) confidence[field] = VoiceConfidenceLevel.high;
    }

    mark(
      VoiceConfidenceField.party,
      draft.partyName != null && normalized.contains(draft.partyName!.toLowerCase()),
    );
    mark(
      VoiceConfidenceField.item,
      draft.itemName != null && normalized.contains(draft.itemName!.toLowerCase()),
    );
    mark(
      VoiceConfidenceField.quantity,
      draft.quantity != null && normalized.contains(draft.quantity!.round().toString()),
    );
    mark(
      VoiceConfidenceField.rate,
      draft.rate != null && normalized.contains(draft.rate!.round().toString()),
    );
    if (draft.paymentBreakdown.cash > 0) {
      mark(VoiceConfidenceField.cash, normalized.contains('cash') || normalized.contains('nakd'));
    }
    if (draft.paymentBreakdown.upi > 0) {
      mark(VoiceConfidenceField.upi, normalized.contains('upi'));
    }
    if (draft.paymentBreakdown.bank > 0) {
      mark(VoiceConfidenceField.bank, normalized.contains('bank'));
    }
  }

  bool _isContinuation(String text) {
    return _hasAny(text, [
      'aur bhej',
      'aur bhejo',
      'bhej do',
      'bhejo',
      'phir se',
      'wapas bhej',
      'same order',
      'wahi maal',
    ]);
  }

  bool _wantsSameRate(String text) {
    return _hasAny(text, [
      'usi rate',
      'usi rate par',
      'same rate',
      'wahi rate',
      'purana rate',
      'pichla rate',
    ]);
  }

  bool _mentionsMaalOnly(String text) {
    return text.contains(' maal ') && !RegExp(r'\d+\s*(kilo|kg|piece)').hasMatch(text);
  }

  bool _hasReminderKeyword(String text) {
    return _hasAny(text, ['reminder', 'yaad dilana', 'yaad dilao', 'yaad rakh']);
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _hasAny(String text, List<String> needles) => needles.any(text.contains);

  bool _same(String? a, String? b) {
    if (a == null || b == null) return false;
    return a.trim().toLowerCase() == b.trim().toLowerCase();
  }
}
