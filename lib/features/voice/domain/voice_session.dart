import 'voice_draft.dart';

/// Steps in the full-screen Voice Assistant flow.
enum VoiceAssistantStep {
  listening,
  transcript,
  processing,
  preview,
  permissionDenied,
}

/// In-memory session state for one voice interaction.
class VoiceSessionState {
  const VoiceSessionState({
    this.step = VoiceAssistantStep.listening,
    this.transcript = '',
    this.isListening = false,
    this.isBusy = false,
    this.error,
    this.resolved,
  });

  final VoiceAssistantStep step;
  final String transcript;
  final bool isListening;
  final bool isBusy;
  final String? error;
  final VoiceResolvedDraft? resolved;

  VoiceSessionState copyWith({
    VoiceAssistantStep? step,
    String? transcript,
    bool? isListening,
    bool? isBusy,
    String? error,
    VoiceResolvedDraft? resolved,
    bool clearError = false,
    bool clearResolved = false,
  }) {
    return VoiceSessionState(
      step: step ?? this.step,
      transcript: transcript ?? this.transcript,
      isListening: isListening ?? this.isListening,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
      resolved: clearResolved ? null : (resolved ?? this.resolved),
    );
  }
}
