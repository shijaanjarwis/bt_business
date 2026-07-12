import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../items/presentation/providers/item_providers.dart';
import '../../../ledger/domain/usecases/search_parties.dart';
import '../../../ledger/presentation/providers/party_providers.dart';
import '../../domain/voice_draft.dart';
import '../../domain/voice_intent_type.dart';

/// Resolves party and item names against local data — asks before creating.
final class VoiceEntityResolver {
  VoiceEntityResolver({
    required WidgetRef ref,
  }) : _ref = ref;

  final WidgetRef _ref;

  Future<VoiceResolvedDraft> resolve(VoiceDraft draft) async {
    var resolved = VoiceResolvedDraft(draft: draft);

    if (_needsParty(draft.intent)) {
      final partyResult = await _resolveParty(draft.partyName!);
      if (partyResult.needsCreate) {
        return resolved.copyWith(createParty: true);
      }
      resolved = resolved.copyWith(partyId: partyResult.id);
    }

    if (_needsItem(draft.intent)) {
      final itemResult = await _resolveItem(draft.itemName!);
      if (itemResult.needsCreate) {
        return resolved.copyWith(
          partyId: resolved.partyId,
          createItem: true,
        );
      }
      resolved = resolved.copyWith(itemId: itemResult.id);
    }

    return resolved;
  }

  bool _needsParty(VoiceIntentType intent) {
    return switch (intent) {
      VoiceIntentType.sale ||
      VoiceIntentType.purchase ||
      VoiceIntentType.paymentReceived ||
      VoiceIntentType.paymentPaid ||
      VoiceIntentType.reminder =>
        true,
      _ => false,
    };
  }

  bool _needsItem(VoiceIntentType intent) {
    return intent == VoiceIntentType.sale || intent == VoiceIntentType.purchase;
  }

  Future<_EntityLookup> _resolveParty(String name) async {
    final result = await _ref.read(searchPartiesUseCaseProvider)(
      SearchPartiesParams(query: name),
    );
    if (result.isFailure) return _EntityLookup(needsCreate: true);

    final parties = result.valueOrNull ?? [];
    if (parties.isEmpty) return _EntityLookup(needsCreate: true);

    final exact = parties.where(
      (party) => party.name.toLowerCase() == name.toLowerCase(),
    );
    if (exact.isNotEmpty) {
      return _EntityLookup(id: exact.first.id);
    }

    final contains = parties.where(
      (party) =>
          party.name.toLowerCase().contains(name.toLowerCase()) ||
          name.toLowerCase().contains(party.name.toLowerCase()),
    );
    if (contains.isNotEmpty) {
      return _EntityLookup(id: contains.first.id);
    }

    return _EntityLookup(id: parties.first.id);
  }

  Future<_EntityLookup> _resolveItem(String name) async {
    final result = await _ref.read(itemRepositoryProvider).findByName(name);
    if (result.isFailure) return _EntityLookup(needsCreate: true);
    final item = result.valueOrNull;
    if (item != null) return _EntityLookup(id: item.id);

    final search = await _ref.read(itemRepositoryProvider).searchItems(name);
    if (search.isFailure) return _EntityLookup(needsCreate: true);
    final items = search.valueOrNull ?? [];
    if (items.isEmpty) return _EntityLookup(needsCreate: true);
    return _EntityLookup(id: items.first.id);
  }
}

class _EntityLookup {
  const _EntityLookup({this.id, this.needsCreate = false});

  final String? id;
  final bool needsCreate;
}
