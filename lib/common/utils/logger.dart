import 'dart:developer' as dev;

/// Lightweight logger using `dart:developer` log.
/// Shows up in DevTools and doesn't trigger `avoid_print`.
///
/// Usage:
/// ```dart
/// const _log = AppLogger('📷', 'CAPTURE');
/// _log.info('Picking image');
/// _log.error('Failed to load');
/// ```
class AppLogger {
  final String emoji;
  final String tag;

  const AppLogger(this.emoji, this.tag);

  void info(String message) {
    dev.log('$emoji [$tag] $message', name: tag);
  }

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    dev.log(
      '$emoji [$tag] $message',
      name: tag,
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }
}
