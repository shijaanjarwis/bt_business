import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_text_theme.dart';
import '../../../../core/theme/color_palette.dart';
import '../../domain/voice_memory.dart';
import '../providers/voice_providers.dart';

/// Recent party/item chips from on-device memory — tap to fill fields.
class VoiceSuggestionsStrip extends ConsumerWidget {
  const VoiceSuggestionsStrip({
    super.key,
    required this.onPartyTap,
    required this.onItemTap,
  });

  final ValueChanged<String> onPartyTap;
  final ValueChanged<String> onItemTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.appText;
    final store = ref.watch(voiceBusinessMemoryStoreProvider);

    return FutureBuilder<List<VoiceMemoryPattern>>(
      future: store.readAll(),
      builder: (context, snapshot) {
        final patterns = snapshot.data ?? [];
        if (patterns.isEmpty) return const SizedBox.shrink();

        final parties = patterns
            .map((p) => p.partyName)
            .whereType<String>()
            .toSet()
            .take(4)
            .toList();
        final items = patterns
            .map((p) => p.itemName)
            .whereType<String>()
            .toSet()
            .take(4)
            .toList();

        if (parties.isEmpty && items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Yaad se sujhav', style: text.helper.copyWith(fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...parties.map(
                  (name) => ActionChip(
                    label: Text(name, style: text.secondary),
                    backgroundColor: ColorPalette.cardSurface,
                    side: const BorderSide(color: ColorPalette.border),
                    onPressed: () => onPartyTap(name),
                  ),
                ),
                ...items.map(
                  (name) => ActionChip(
                    label: Text(name, style: text.secondary),
                    backgroundColor: ColorPalette.purple.withValues(alpha: 0.06),
                    side: BorderSide(color: ColorPalette.purple.withValues(alpha: 0.25)),
                    onPressed: () => onItemTap(name),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
