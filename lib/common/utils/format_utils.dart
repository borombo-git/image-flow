import 'package:intl/intl.dart';

final _dateFormat = DateFormat('MMM d, h:mm a');
final _dateLongFormat = DateFormat("MMM d, yyyy 'at' h:mm a");

/// Formats a [DateTime] as "Oct 24, 10:30 AM".
String formatDate(DateTime date) => _dateFormat.format(date);

/// Formats a [DateTime] as "Oct 24, 2024 at 10:30 AM".
String formatDateLong(DateTime date) => _dateLongFormat.format(date);

/// Formats milliseconds as "350ms" or "1.2s".
String formatDuration(int ms) {
  if (ms < 1000) return '${ms}ms';
  return '${(ms / 1000).toStringAsFixed(1)}s';
}

/// Formats bytes as "1.2 KB", "3.4 MB", etc.
String formatFileSize(int bytes) {
  if (bytes <= 0) return '—';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
