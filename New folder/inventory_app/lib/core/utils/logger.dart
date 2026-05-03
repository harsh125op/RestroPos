import 'package:flutter/foundation.dart';

/// A centralized logger for the application.
/// In production, this can be extended to send logs to a remote service.
class AppLogger {
  static void d(String message) {
    if (kDebugMode) {
      debugPrint('DEBUG: $message');
    }
  }

  static void i(String message) {
    debugPrint('INFO: $message');
  }

  static void w(String message) {
    debugPrint('WARNING: $message');
  }

  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    debugPrint('ERROR: $message');
    if (error != null) {
      debugPrint('Error details: $error');
    }
    if (stackTrace != null) {
      debugPrint('StackTrace: $stackTrace');
    }
    
    // TODO: Integrate with Crashlytics or Sentry here for production
  }
}
