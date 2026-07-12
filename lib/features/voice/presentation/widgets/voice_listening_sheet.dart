import 'package:flutter/material.dart';

import '../pages/voice_assistant_page.dart';

/// @deprecated Use [VoiceAssistantPage.open] — full-screen assistant.
abstract final class VoiceListeningSheet {
  static Future<void> show(BuildContext context, dynamic ref) {
    return VoiceAssistantPage.open(context);
  }
}
