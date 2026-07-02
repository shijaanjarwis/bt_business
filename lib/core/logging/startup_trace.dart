import 'package:flutter/foundation.dart';

/// Temporary startup tracing — visible in release via Xcode / `flutter run` logs.
abstract final class StartupTrace {
  static final Set<String> _once = {};

  static void log(String stage) {
    debugPrint('[BT Startup] $stage');
  }

  static void logOnce(String stage) {
    if (_once.add(stage)) {
      log(stage);
    }
  }
}
