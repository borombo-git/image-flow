import 'dart:io';

import 'package:path_provider/path_provider.dart';

late final String _docsDir;

/// Must be called once at startup before accessing [resolveDocPath].
Future<void> initDocsDir() async {
  final dir = await getApplicationDocumentsDirectory();
  _docsDir = dir.path;
}

/// Returns the cached application documents directory path.
String get docsDir => _docsDir;

/// Resolves a stored path (filename or legacy absolute path) to the current
/// documents directory.
///
/// On iOS the sandbox UUID can change between builds, making stored absolute
/// paths stale. This extracts the filename and joins it with the current
/// documents directory so images are always found.
String resolveDocPath(String stored) {
  if (!stored.contains('/')) {
    return '$_docsDir/$stored';
  }
  final filename = stored.split('/').last;
  return '$_docsDir/$filename';
}

/// Copies [sourcePath] into the documents directory and returns just the
/// filename (not the full path).
Future<String> copyToDocuments(String sourcePath) async {
  final source = File(sourcePath);
  final filename = 'original_${DateTime.now().millisecondsSinceEpoch}.jpg';
  await source.copy('$_docsDir/$filename');
  return filename;
}
