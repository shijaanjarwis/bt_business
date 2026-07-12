/// Visual + status states shown on the Voice Assistant screen.
enum VoiceCaptureUiState {
  preparing,
  listening,
  voiceDetected,
  completed,
  noSpeech,
  processing,
  error,
}

extension VoiceCaptureUiStateX on VoiceCaptureUiState {
  String get statusMessage => switch (this) {
        VoiceCaptureUiState.preparing => 'Tayyar ho raha hoon...',
        VoiceCaptureUiState.listening => '🎤 Sun raha hoon...',
        VoiceCaptureUiState.voiceDetected => '🎤 Sun raha hoon...',
        VoiceCaptureUiState.completed => '✅ Ho gaya',
        VoiceCaptureUiState.noSpeech => '😕 Kuch sunai nahi diya.\nDobara boliye.',
        VoiceCaptureUiState.processing => '🧠 Samajh raha hoon...',
        VoiceCaptureUiState.error => 'Kuch gadbad ho gayi. Phir se koshish karein.',
      };

  bool get showWaveAnimation =>
      this == VoiceCaptureUiState.listening || this == VoiceCaptureUiState.voiceDetected;

  bool get micPulseActive =>
      this == VoiceCaptureUiState.listening ||
      this == VoiceCaptureUiState.voiceDetected ||
      this == VoiceCaptureUiState.preparing;
}
