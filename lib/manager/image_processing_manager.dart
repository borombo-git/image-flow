import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:image/image.dart' as img;

import '../common/exceptions/processing_exceptions.dart';
import '../common/utils/logger.dart';
import '../common/utils/path_utils.dart';
import '../model/processing_record.dart';
import 'document_processor.dart';
import 'face_processor.dart';

const _log = AppLogger('🧠', 'PROCESSING');

/// Progress callback: (progress 0→1, step title, step description).
typedef ProgressCallback = void Function(
  double progress,
  String step,
  String description,
);

/// Saves JPEG bytes to app documents directory. Returns the filename only.
/// Shared by [FaceProcessor] and [DocumentProcessor].
Future<String> saveResult(Uint8List bytes, {required String prefix}) async {
  final fileName = '$prefix${DateTime.now().millisecondsSinceEpoch}.jpg';
  final file = File('$docsDir/$fileName');
  await file.writeAsBytes(bytes);
  return fileName;
}

/// Top-level function for [Isolate.run].
/// Decodes image, applies EXIF rotation to pixels, re-encodes as JPEG.
/// The output has no EXIF orientation tag — pixels are in the correct layout.
Uint8List _normalizeOrientation(Uint8List rawBytes) {
  final decoded = img.decodeImage(rawBytes);
  if (decoded == null) throw Exception('Failed to decode image');
  final baked = img.bakeOrientation(decoded);
  return img.encodeJpg(baked, quality: 95);
}

/// Global singleton that auto-detects content type and delegates to the
/// appropriate processor.
class ImageProcessingManager extends GetxController {
  final _faceProcessor = FaceProcessor();
  final _documentProcessor = DocumentProcessor();

  /// Auto-detects content type and runs the appropriate pipeline.
  ///
  /// Normalizes EXIF orientation upfront so ML Kit detection coordinates
  /// and isolate pixel manipulation share the same coordinate space.
  ///
  /// Heuristic: text recognizer first (cheap) — if >= 3 text blocks → document
  /// flow, else → face detector fallback, else → [NoContentDetectedException].
  Future<ProcessingRecord> processImage(
    String imagePath, {
    ProgressCallback? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();

    // 1. Read and normalize orientation in isolate
    onProgress?.call(0.0, 'Loading Image', 'Reading image from storage');
    _log.info('Reading image: $imagePath');
    final rawBytes = await File(imagePath).readAsBytes();

    _log.info('Normalizing EXIF orientation');
    final bytes = await Isolate.run(() => _normalizeOrientation(rawBytes));

    // 2. Write normalized image to temp file for ML Kit
    //    (ML Kit uses platform channels → needs a file path, not raw bytes)
    final tempPath = '$docsDir/.temp_normalized.jpg';
    await File(tempPath).writeAsBytes(bytes);

    try {
      // 3. Text detection (cheap — run first for auto-detection)
      onProgress?.call(0.1, 'Analyzing Content', 'Detecting content type');
      _log.info('Running text recognition for auto-detection');
      final textBlocks = await _documentProcessor.detect(tempPath);
      _log.info('Text blocks found: ${textBlocks.length}');

      if (textBlocks.length >= 3) {
        _log.info('Document detected (${textBlocks.length} text blocks)');
        return _documentProcessor.process(
          imagePath,
          bytes,
          textBlocks,
          stopwatch: stopwatch,
          onProgress: onProgress,
        );
      }

      // 4. Face detection fallback
      onProgress?.call(0.2, 'Detecting Faces', 'Scanning for faces with ML Kit');
      _log.info('Running face detection fallback');
      final faceRects = await _faceProcessor.detect(tempPath);

      if (faceRects.isNotEmpty) {
        _log.info('Detected ${faceRects.length} face(s)');
        return _faceProcessor.process(
          imagePath,
          bytes,
          faceRects,
          stopwatch: stopwatch,
          onProgress: onProgress,
        );
      }

      // 5. Nothing detected
      _log.info('No content detected — neither text nor faces');
      throw const NoContentDetectedException();
    } finally {
      // Clean up temp file
      try {
        await File(tempPath).delete();
      } catch (_) {}
    }
  }
}
