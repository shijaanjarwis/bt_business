import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/sheets/app_bottom_sheet.dart';
import '../../data/parsers/rule_voice_parser.dart';
import '../pages/voice_preview_page.dart';
import '../providers/voice_providers.dart';
import '../services/voice_entity_resolver.dart';

/// Voice capture sheet — listen, correct text, parse, then open preview.
class VoiceListeningSheet extends ConsumerStatefulWidget {
  const VoiceListeningSheet({super.key});

  static Future<void> show(BuildContext context, WidgetRef ref) {
    return showAppBottomSheet<void>(
      context: context,
      isDismissible: true,
      builder: (context) => const VoiceListeningSheet(),
    );
  }

  @override
  ConsumerState<VoiceListeningSheet> createState() => _VoiceListeningSheetState();
}

class _VoiceListeningSheetState extends ConsumerState<VoiceListeningSheet>
    with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  late final AnimationController _pulseController;

  bool _isListening = false;
  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startListening());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    ref.read(speechRecognizerProvider).cancelListening();
    super.dispose();
  }

  Future<void> _startListening() async {
    setState(() {
      _error = null;
      _isListening = true;
    });

    final locale = ref.read(voiceLocaleProvider);
    final speech = ref.read(speechRecognizerProvider);
    final ready = await speech.initialize(localeId: locale);
    if (!ready) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _error = 'Mic permission ya voice service available nahi hai';
        });
      }
      return;
    }

    await speech.startListening(
      onResult: (words) {
        if (!mounted) return;
        setState(() => _textController.text = words);
      },
      onError: (message) {
        if (!mounted) return;
        setState(() {
          _error = message;
          _isListening = false;
        });
      },
      onDone: () {
        if (!mounted) return;
        setState(() => _isListening = false);
      },
    );
  }

  Future<void> _stopListening() async {
    await ref.read(speechRecognizerProvider).stopListening();
    if (mounted) setState(() => _isListening = false);
  }

  Future<void> _processTranscript() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Pehle kuch boliye ya type karein');
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      await ref.read(voiceHistoryStoreProvider).add(text);
      ref.invalidate(voiceHistoryProvider);

      final parser = ref.read(voiceParserProvider) as RuleVoiceParser;
      final memoryEngine = ref.read(voiceMemoryEngineProvider);
      var result = parser.parse(text);
      var enriched = await memoryEngine.enrich(parseResult: result, rawText: text);
      var draft = enriched.draft;

      while (enriched.needsClarification && mounted) {
        final clarification = enriched.clarification!;
        final answer = await _askClarification(clarification.question);
        if (!mounted) return;
        if (answer == null || answer.trim().isEmpty) {
          setState(() => _isProcessing = false);
          return;
        }
        draft = applyClarificationAnswer(draft, clarification, answer);
        result = revalidateVoiceDraft(draft, parser);
        enriched = await memoryEngine.enrich(parseResult: result, rawText: text);
        draft = enriched.draft;
      }

      if (!mounted) return;

      final resolver = VoiceEntityResolver(ref: ref);
      var resolved = await resolver.resolve(draft);
      resolved = resolved.copyWith(
        confidence: enriched.confidence,
        memoryUsed: enriched.memoryUsed,
      );

      if (resolved.createParty && mounted) {
        final yes = await _confirm(
          title: 'Nayi party banayein?',
          message: '${draft.partyName} abhi list mein nahi hai.',
        );
        if (!mounted) return;
        if (yes != true) {
          setState(() => _isProcessing = false);
          return;
        }
        resolved = resolved.copyWith(createParty: true);
      }

      if (resolved.createItem && mounted) {
        final yes = await _confirm(
          title: 'Naya maal banayein?',
          message: '${draft.itemName} abhi list mein nahi hai.',
        );
        if (!mounted) return;
        if (yes != true) {
          setState(() => _isProcessing = false);
          return;
        }
        resolved = resolved.copyWith(createItem: true);
      }

      if (!mounted) return;
      Navigator.pop(context);
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => VoicePreviewPage(resolved: resolved),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<String?> _askClarification(String question) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Thodi aur jaankari'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(question),
              const SizedBox(height: 12),
              AppTextField(
                english: 'Answer',
                hindi: 'Jawaab',
                controller: controller,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Theek Hai'),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Nahi'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Haan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(voiceHistoryProvider);

    return AppBottomSheetLayout(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Boliye — BT Business samjhega',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Center(
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.08).animate(
                CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
              ),
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening
                      ? ColorPalette.purple
                      : ColorPalette.purple.withValues(alpha: 0.2),
                ),
                child: Icon(
                  Icons.mic_rounded,
                  size: 40,
                  color: _isListening ? Colors.white : ColorPalette.purple,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _isListening ? 'Sun raha hoon...' : 'Mic band hai',
              style: const TextStyle(color: ColorPalette.labelSecondary),
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(
            english: 'Recognized Text',
            hindi: 'Jo suna / type karein',
            controller: _textController,
            maxLines: 4,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: ColorPalette.destructive),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isProcessing
                      ? null
                      : () {
                          if (_isListening) {
                            _stopListening();
                          } else {
                            _startListening();
                          }
                        },
                  child: Text(_isListening ? 'Ruken' : 'Phir Sunen'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppPrimaryButton(
                  english: 'Preview',
                  hindi: 'Dekhein',
                  isLoading: _isProcessing,
                  onPressed: _isProcessing ? null : _processTranscript,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Purani awaaz',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          historyAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (entries) {
              if (entries.isEmpty) {
                return const Text(
                  'Abhi koi command nahi',
                  style: TextStyle(color: ColorPalette.labelSecondary),
                );
              }
              return Column(
                children: entries.take(5).map((entry) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      entry,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.replay_rounded, size: 18),
                    onTap: () {
                      _textController.text = entry;
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
