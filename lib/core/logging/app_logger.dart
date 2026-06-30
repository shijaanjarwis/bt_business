import 'package:flutter/foundation.dart';

import 'logger.dart';

/// Default [Logger] — verbose in debug, errors always recorded.
final class AppLogger implements Logger {
  const AppLogger();

  static const String _prefix = '[BT Business]';

  @override
  void debug(String message) {
    if (kDebugMode) {
      debugPrint('$_prefix DEBUG $message');
    }
  }

  @override
  void info(String message) {
    if (kDebugMode) {
      debugPrint('$_prefix INFO  $message');
    }
  }

  @override
  void warning(String message) {
    debugPrint('$_prefix WARN  $message');
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('$_prefix ERROR $message');
    if (error != null) {
      debugPrint('$_prefix        $error');
    }
    if (stackTrace != null && kDebugMode) {
      debugPrint('$_prefix        $stackTrace');
    }
  }
}
