import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/app_text_theme.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/branding/developer_footer.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/dialogs/app_dialog.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../data/speech/speech_permission_status.dart';
import '../../domain/voice_capture_ui_state.dart';
import '../../domain/voice_session.dart';
import '../../engine/preview_generator.dart';
import '../../engine/voice_manager.dart';
import '../pages/voice_preview_page.dart';
import '../providers/voice_providers.dart';
import '../services/voice_entity_resolver.dart';
import '../widgets/voice_animated_mic.dart';

/// Full-screen Voice Assistant — listen, edit, preview, save.
class VoiceAssistantPage extends ConsumerStatefulWidget {
  const VoiceAssistantPage({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => const VoiceAssistantPage(),
      ),
    );
  }

  @override
  ConsumerState<VoiceAssistantPage> createState() => _VoiceAssistantPageState();
}

class _VoiceAssistantPageState extends ConsumerState<VoiceAssistantPage>
    with TickerProviderStateMixin {
  static const _noSpeechTimeout = Duration(seconds: 8);
  static const _voiceLevelThreshold = 0.12;

  VoiceSessionState _session = const VoiceSessionState();
  VoiceCaptureUiState _uiState = VoiceCaptureUiState.preparing;
  final _textController = TextEditingController();
  late final AnimationController _pulseController;
  late final AnimationController _glowController;
  Timer? _noSpeechTimer;
  Timer? _soundLevelTimer;
  VoiceManager? _managerRef;
  double _soundLevel = 0;
  double _pendingSoundLevel = 0;
  String? _customStatusMessage;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _textController.addListener(_onTranscriptEdited);
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareAndListen());
  }

  @override
  void dispose() {
    _noSpeechTimer?.cancel();
    _soundLevelTimer?.cancel();
    _pulseController.dispose();
    _glowController.dispose();
    _textController.removeListener(_onTranscriptEdited);
    _textController.dispose();
    _managerRef?.cancelListening();
    super.dispose();
  }

  VoiceManager get _manager {
    _managerRef ??= ref.read(voiceManagerProvider);
    return _managerRef!;
  }

  void _onTranscriptEdited() {
    if (!mounted) return;
    setState(() {});
  }

  String get _statusMessage => _customStatusMessage ?? _uiState.statusMessage;

  bool get _hasTranscript => _textController.text.trim().isNotEmpty;

  void _setUiState(VoiceCaptureUiState state, {String? message, bool clearMessage = false}) {
    setState(() {
      _uiState = state;
      if (clearMessage) {
        _customStatusMessage = null;
      } else if (message != null) {
        _customStatusMessage = message;
      }
    });
  }

  Future<void> _prepareAndListen() async {
    _noSpeechTimer?.cancel();
    _setUiState(VoiceCaptureUiState.preparing, clearMessage: true);
    setState(() {
      _session = _session.copyWith(
        step: VoiceAssistantStep.listening,
        isListening: false,
        clearError: true,
      );
    });

    final permission = await _manager.ensureMicrophonePermission();
    if (!mounted) return;

    if (permission != SpeechPermissionStatus.granted) {
      setState(() {
        _session = _session.copyWith(step: VoiceAssistantStep.permissionDenied);
      });
      return;
    }

    await _beginListening();
  }

  Future<void> _beginListening() async {
    _noSpeechTimer?.cancel();
    await _manager.stopListening();

    if (!mounted) return;
    setState(() {
      _session = _session.copyWith(
        step: VoiceAssistantStep.listening,
        isListening: true,
        clearError: true,
      );
      _soundLevel = 0;
      _pendingSoundLevel = 0;
    });
    _setUiState(VoiceCaptureUiState.listening, clearMessage: true);

    final locale = ref.read(voiceLocaleProvider);
    final ready = await _manager.initializeSpeech(locale);
    if (!mounted) return;

    if (!ready) {
      final permission = await _manager.ensureMicrophonePermission();
      if (!mounted) return;
      if (permission != SpeechPermissionStatus.granted) {
        setState(() {
          _session = _session.copyWith(
            step: VoiceAssistantStep.permissionDenied,
            isListening: false,
          );
        });
        return;
      }
      _handleError('Voice service abhi available nahi hai. Phir se koshish karein.');
      return;
    }

    _startNoSpeechTimer();

    await _manager.startListening(
      onResult: (words) {
        if (!mounted) return;
        _noSpeechTimer?.cancel();
        _textController.text = words;
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: words.length),
        );
        setState(() {
          _session = _session.copyWith(transcript: words);
          if (_uiState == VoiceCaptureUiState.listening ||
              _uiState == VoiceCaptureUiState.voiceDetected) {
            _uiState = VoiceCaptureUiState.listening;
            _customStatusMessage = null;
          }
        });
        if (_session.isListening) {
          _startNoSpeechTimer();
        }
      },
      onSoundLevel: (level) {
        _pendingSoundLevel = level;
        _soundLevelTimer ??= Timer.periodic(const Duration(milliseconds: 100), (_) {
          if (!mounted) return;
          final detected = _pendingSoundLevel >= _voiceLevelThreshold;
          setState(() {
            _soundLevel = _pendingSoundLevel;
            if (_session.isListening && detected) {
              _uiState = VoiceCaptureUiState.voiceDetected;
              _customStatusMessage = null;
            } else if (_session.isListening && _uiState == VoiceCaptureUiState.voiceDetected) {
              _uiState = VoiceCaptureUiState.listening;
            }
          });
        });
      },
      onError: (message) {
        if (!mounted) return;
        _noSpeechTimer?.cancel();
        _handleError(message);
      },
      onDone: () {
        if (!mounted) return;
        _noSpeechTimer?.cancel();
        final text = _textController.text.trim();
        if (text.isEmpty) {
          setState(() {
            _session = _session.copyWith(isListening: false);
            _uiState = VoiceCaptureUiState.noSpeech;
            _customStatusMessage = null;
            _soundLevel = 0;
          });
          return;
        }
        setState(() {
          _session = _session.copyWith(isListening: false, transcript: text);
          _uiState = VoiceCaptureUiState.completed;
          _customStatusMessage = null;
          _soundLevel = 0;
        });
      },
    );
  }

  void _startNoSpeechTimer() {
    _noSpeechTimer?.cancel();
    _noSpeechTimer = Timer(_noSpeechTimeout, () async {
      if (!mounted || !_session.isListening) return;
      if (_textController.text.trim().isNotEmpty) return;
      await _manager.stopListening();
      if (!mounted) return;
      setState(() {
        _session = _session.copyWith(isListening: false);
        _uiState = VoiceCaptureUiState.noSpeech;
        _customStatusMessage = null;
        _soundLevel = 0;
      });
    });
  }

  void _handleError(String message) {
    setState(() {
      _session = _session.copyWith(isListening: false, error: message);
      _uiState = VoiceCaptureUiState.error;
      _customStatusMessage = message;
      _soundLevel = 0;
    });
  }

  Future<void> _openSettings() async {
    await openAppSettings();
  }

  Future<void> _processTranscript() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _handleError('Pehle kuch boliye ya type karein');
      return;
    }

    await _manager.stopListening();
    if (!mounted) return;

    setState(() {
      _session = _session.copyWith(
        step: VoiceAssistantStep.processing,
        isBusy: true,
        isListening: false,
        clearError: true,
      );
      _uiState = VoiceCaptureUiState.processing;
      _customStatusMessage = null;
    });

    try {
      await _manager.recordHistory(text);
      ref.invalidate(voiceHistoryProvider);

      var enriched = await _manager.parseTranscript(text);
      var draft = enriched.draft;

      while (enriched.needsClarification && mounted) {
        final clarification = enriched.clarification!;
        final answer = await _askClarification(clarification.question);
        if (!mounted) return;
        if (answer == null || answer.trim().isEmpty) {
          setState(() {
            _session = _session.copyWith(
              step: VoiceAssistantStep.listening,
              isBusy: false,
            );
            _uiState = _hasTranscript ? VoiceCaptureUiState.completed : VoiceCaptureUiState.noSpeech;
          });
          return;
        }
        enriched = await _manager.applyClarification(
          draft: draft,
          clarification: clarification,
          answer: answer,
          rawText: text,
        );
        draft = enriched.draft;
      }

      if (!mounted) return;

      final resolver = VoiceEntityResolver(ref: ref);
      var resolved = await resolver.resolve(draft);
      resolved = resolved.copyWith(
        confidence: enriched.confidence,
        memoryUsed: enriched.memoryUsed,
        overallConfidence: enriched.overallConfidence,
      );

      if (resolved.createParty && mounted) {
        final yes = await _confirm(
          title: 'Nayi party banayein?',
          message: '${draft.partyName} abhi list mein nahi hai.',
        );
        if (!mounted) return;
        if (yes != true) {
          setState(() {
            _session = _session.copyWith(step: VoiceAssistantStep.listening, isBusy: false);
            _uiState = VoiceCaptureUiState.completed;
          });
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
          setState(() {
            _session = _session.copyWith(step: VoiceAssistantStep.listening, isBusy: false);
            _uiState = VoiceCaptureUiState.completed;
          });
          return;
        }
        resolved = resolved.copyWith(createItem: true);
      }

      PreviewGenerator.fromResolved(resolved);

      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => VoicePreviewPage(resolved: resolved),
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _session = _session.copyWith(step: VoiceAssistantStep.listening, isBusy: false);
        });
        _handleError('$error');
      }
    }
  }

  Future<String?> _askClarification(String question) async {
    final controller = TextEditingController();
    return AppDialog.show<String>(
      context,
      child: AlertDialog(
        backgroundColor: AppDialog.surface,
        surfaceTintColor: Colors.transparent,
        title: Text('Thodi aur jaankari', style: context.appText.dialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(question, style: context.appText.dialogBody),
            const SizedBox(height: 12),
            AppTextField(
              english: 'Answer',
              hindi: 'Jawaab',
              controller: controller,
            ),
          ],
        ),
        actions: [
          AppDialog.action(
            context: context,
            label: 'Cancel',
            onPressed: () => Navigator.pop(context),
          ),
          AppDialog.filledAction(
            context: context,
            label: 'Theek Hai',
            onPressed: () => Navigator.pop(context, controller.text),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirm({required String title, required String message}) {
    return AppDialog.show<bool>(
      context,
      child: AppDialog.shell(
        context: context,
        title: title,
        message: message,
        actions: [
          AppDialog.action(
            context: context,
            label: 'Nahi',
            onPressed: () => Navigator.pop(context, false),
          ),
          AppDialog.filledAction(
            context: context,
            label: 'Haan',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    final text = context.appText;

    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: AppBar(
        backgroundColor: ColorPalette.cardSurface,
        foregroundColor: ColorPalette.labelPrimary,
        elevation: 0,
        title: Text(
          'Voice Assistant',
          style: text.primaryBold.copyWith(fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: switch (_session.step) {
        VoiceAssistantStep.permissionDenied => _PermissionDeniedStep(
            onOpenSettings: _openSettings,
            onCancel: () => Navigator.of(context).pop(),
          ),
        VoiceAssistantStep.processing => _ProcessingStep(message: _statusMessage),
        VoiceAssistantStep.preview => const SizedBox.shrink(),
        _ => _ActiveAssistantStep(
            textTheme: text,
            pulse: _pulseController,
            glow: _glowController,
            uiState: _uiState,
            statusMessage: _statusMessage,
            isListening: _session.isListening,
            isBusy: _session.isBusy,
            soundLevel: _soundLevel,
            controller: _textController,
            hasTranscript: _hasTranscript,
            bottomInset: safeBottom,
            onListenAgain: _beginListening,
            onPreview: _processTranscript,
          ),
      },
    );
  }
}

class _PermissionDeniedStep extends StatelessWidget {
  const _PermissionDeniedStep({
    required this.onOpenSettings,
    required this.onCancel,
  });

  final VoidCallback onOpenSettings;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final text = context.appText;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Icon(Icons.mic_off_rounded, size: 72, color: ColorPalette.destructive),
            const SizedBox(height: 24),
            Text(
              'Microphone permission zaroori hai.',
              textAlign: TextAlign.center,
              style: text.primaryBold.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 12),
            Text(
              'BT Business aapki awaaz se entry banane ke liye mic use karta hai. Settings se permission dein.',
              textAlign: TextAlign.center,
              style: text.helper.copyWith(fontSize: 15, height: 1.45),
            ),
            const Spacer(),
            AppPrimaryButton(
              english: 'Open Settings',
              hindi: 'Settings Kholein',
              onPressed: onOpenSettings,
            ),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: onCancel, child: const Text('Cancel')),
            const SizedBox(height: 12),
            const DeveloperFooter(),
          ],
        ),
      ),
    );
  }
}

class _ProcessingStep extends StatelessWidget {
  const _ProcessingStep({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final text = context.appText;
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(strokeWidth: 3, color: ColorPalette.purple),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: text.hindi.copyWith(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveAssistantStep extends ConsumerWidget {
  const _ActiveAssistantStep({
    required this.textTheme,
    required this.pulse,
    required this.glow,
    required this.uiState,
    required this.statusMessage,
    required this.isListening,
    required this.isBusy,
    required this.soundLevel,
    required this.controller,
    required this.hasTranscript,
    required this.bottomInset,
    required this.onListenAgain,
    required this.onPreview,
  });

  final AppTextTheme textTheme;
  final AnimationController pulse;
  final AnimationController glow;
  final VoiceCaptureUiState uiState;
  final String statusMessage;
  final bool isListening;
  final bool isBusy;
  final double soundLevel;
  final TextEditingController controller;
  final bool hasTranscript;
  final double bottomInset;
  final VoidCallback onListenAgain;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(voiceHistoryProvider);
    final isError = uiState == VoiceCaptureUiState.error || uiState == VoiceCaptureUiState.noSpeech;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                VoiceAnimatedMic(
                  pulse: pulse,
                  glow: glow,
                  isActive: uiState.micPulseActive,
                  soundLevel: soundLevel,
                  showWave: uiState.showWaveAnimation,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Boliye',
                        style: textTheme.primaryBold.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 2),
                      VoiceStatusLine(
                        message: statusMessage,
                        isError: isError,
                        compact: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Jo suna / type karein',
              style: textTheme.primaryBold.copyWith(fontSize: 17),
            ),
            const SizedBox(height: 4),
            Text(
              'Galat ho to theek kar sakte hain',
              style: textTheme.helper.copyWith(fontSize: 14, height: 1.35),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextFormField(
                controller: controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: textTheme.primary.copyWith(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Yahan awaaz ka text dikhega...',
                  hintStyle: textTheme.secondary.copyWith(fontSize: 15),
                  filled: true,
                  fillColor: ColorPalette.cardSurface,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: ColorPalette.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: ColorPalette.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: ColorPalette.purple, width: 1.5),
                  ),
                ),
              ),
            ),
            if (historyAsync.valueOrNull?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: historyAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (entries) {
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: entries.take(3).length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return ActionChip(
                          label: Text(
                            entry,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.caption.copyWith(fontSize: 12),
                          ),
                          onPressed: () => controller.text = entry,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isBusy ? null : onListenAgain,
                    child: const Text('Phir Sunen'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: AppPrimaryButton(
                    english: 'Preview',
                    hindi: 'Dekhein',
                    compact: true,
                    isLoading: isBusy,
                    onPressed: isBusy || !hasTranscript ? null : onPreview,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
