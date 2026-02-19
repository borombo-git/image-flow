import 'dart:io';
import 'dart:typed_data';

import 'package:get/get.dart';

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

/// Global singleton that auto-detects content type and delegates to the
/// appropriate processor.
class ImageProcessingManager extends GetxController {
  final _faceProcessor = FaceProcessor();
  final _documentProcessor = DocumentProcessor();

  /// Auto-detects content type and runs the appropriate pipeline.
  ///
  /// Heuristic: text recognizer first (cheap) — if >= 3 text blocks → document
  /// flow, else → face detector fallback, else → [NoContentDetectedException].
  Future<ProcessingRecord> processImage(
    String imagePath, {
    ProgressCallback? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();

    // 1. Read image bytes
    onProgress?.call(0.0, 'Loading Image', 'Reading image from storage');
    _log.info('Reading image: $imagePath');
    final bytes = await File(imagePath).readAsBytes();

    // 2. Text detection (cheap — run first for auto-detection)
    onProgress?.call(0.1, 'Analyzing Content', 'Detecting content type');
    _log.info('Running text recognition for auto-detection');
    final textBlocks = await _documentProcessor.detect(imagePath);
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

    // 3. Face detection fallback
    onProgress?.call(0.2, 'Detecting Faces', 'Scanning for faces with ML Kit');
    _log.info('Running face detection fallback');
    final faceRects = await _faceProcessor.detect(imagePath);

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

    // 4. Nothing detected
    _log.info('No content detected — neither text nor faces');
    throw const NoContentDetectedException();
  }
}
