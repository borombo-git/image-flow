import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:image/image.dart' as img;

import '../common/exceptions/processing_exceptions.dart';
import '../common/utils/logger.dart';
import '../common/utils/path_utils.dart';
import '../model/document_page.dart';
import '../model/processing_record.dart';
import 'document_processor.dart';
import 'face_processor.dart';

const _log = AppLogger('🧠', 'PROCESSING');

/// Progress callback: (progress 0→1, step title, step description).
typedef ProgressCallback =
    void Function(double progress, String step, String description);

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

/// Result of [ImageProcessingManager._prepareImage]: EXIF-normalized bytes
/// plus a temp file path for ML Kit.
class _PreparedImage {
  final Uint8List bytes;
  final String tempPath;
  final Stopwatch stopwatch;

  const _PreparedImage(this.bytes, this.tempPath, this.stopwatch);

  /// Cleans up the temp file written for ML Kit.
  Future<void> cleanup() async {
    try {
      await File(tempPath).delete();
    } catch (_) {}
  }
}

/// Global singleton that auto-detects content type and delegates to the
/// appropriate processor.
class ImageProcessingManager extends GetxController {
  final _faceProcessor = FaceProcessor();
  final _documentProcessor = DocumentProcessor();

  /// Exposes the document processor for PDF generation (used by collector).
  DocumentProcessor get documentProcessor => _documentProcessor;

  /// Reads image bytes, normalizes EXIF orientation in an isolate, and writes
  /// a temp file for ML Kit. Shared setup for all processing methods.
  Future<_PreparedImage> _prepareImage(
    String imagePath, {
    ProgressCallback? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();

    onProgress?.call(0.0, 'Loading Image', 'Reading image from storage');
    _log.info('Reading image: $imagePath');
    final rawBytes = await File(imagePath).readAsBytes();

    _log.info('Normalizing EXIF orientation');
    final bytes = await Isolate.run(() => _normalizeOrientation(rawBytes));

    // ML Kit uses platform channels → needs a file path, not raw bytes
    final tempPath = '$docsDir/.temp_normalized.jpg';
    await File(tempPath).writeAsBytes(bytes);

    return _PreparedImage(bytes, tempPath, stopwatch);
  }

  /// Auto-detects content type and returns the appropriate result for the
  /// result screen.
  ///
  /// - Document detected → returns [DocumentPage] (no PDF, no Hive save yet)
  /// - Face detected → returns [ProcessingRecord] (full pipeline, saved to Hive)
  ///
  /// Caller checks return type to route to the correct result view.
  Future<Object> processImageForResult(
    String imagePath, {
    ProgressCallback? onProgress,
  }) async {
    final prepared = await _prepareImage(imagePath, onProgress: onProgress);

    try {
      onProgress?.call(0.1, 'Analyzing Content', 'Detecting content type');
      _log.info('Running text recognition for auto-detection');
      final textBlocks = await _documentProcessor.detect(prepared.tempPath);
      _log.info('Text blocks found: ${textBlocks.length}');

      if (textBlocks.length >= 3) {
        _log.info('Document detected (${textBlocks.length} text blocks)');
        return _documentProcessor.processPage(
          imagePath,
          prepared.bytes,
          textBlocks,
          stopwatch: prepared.stopwatch,
          onProgress: onProgress,
        );
      }

      onProgress?.call(
        0.2,
        'Detecting Faces',
        'Scanning for faces with ML Kit',
      );
      _log.info('Running face detection fallback');
      final faceRects = await _faceProcessor.detect(prepared.tempPath);

      if (faceRects.isNotEmpty) {
        _log.info('Detected ${faceRects.length} face(s)');
        return _faceProcessor.process(
          imagePath,
          prepared.bytes,
          faceRects,
          stopwatch: prepared.stopwatch,
          onProgress: onProgress,
        );
      }

      _log.info('No content detected — neither text nor faces');
      throw const NoContentDetectedException();
    } finally {
      await prepared.cleanup();
    }
  }

  /// Forces the document pipeline for "Add Page" — no auto-detect.
  ///
  /// Returns a [DocumentPage] or throws [NoContentDetectedException] if
  /// the image has fewer than 3 text blocks.
  Future<DocumentPage> processDocumentPage(
    String imagePath, {
    ProgressCallback? onProgress,
  }) async {
    final prepared = await _prepareImage(imagePath, onProgress: onProgress);

    try {
      onProgress?.call(0.1, 'Detecting Text', 'Scanning for document content');
      final textBlocks = await _documentProcessor.detect(prepared.tempPath);
      _log.info('Text blocks found: ${textBlocks.length}');

      if (textBlocks.length < 3) {
        _log.info('Not enough text blocks for document (${textBlocks.length})');
        throw const NoContentDetectedException();
      }

      return _documentProcessor.processPage(
        imagePath,
        prepared.bytes,
        textBlocks,
        stopwatch: prepared.stopwatch,
        onProgress: onProgress,
      );
    } finally {
      await prepared.cleanup();
    }
  }
}
