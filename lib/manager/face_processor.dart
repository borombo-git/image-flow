import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

import '../common/utils/logger.dart';
import '../common/utils/path_utils.dart';
import '../model/processing_record.dart';
import 'history_manager.dart';
import 'image_processing_manager.dart';

const _log = AppLogger('👤', 'FACE');

// ---------------------------------------------------------------------------
// Isolate
// ---------------------------------------------------------------------------

class _IsolatePayload {
  final Uint8List bytes;
  final List<List<int>> boxes; // [x, y, w, h] per face

  const _IsolatePayload(this.bytes, this.boxes);
}

/// Top-level function for [Isolate.run].
/// Decodes pre-normalized image → grayscale each face region → composite → JPEG.
/// Bytes are already EXIF-corrected by the orchestrator, so no bakeOrientation needed.
Uint8List _processInIsolate(_IsolatePayload payload) {
  final image = img.decodeImage(payload.bytes);
  if (image == null) throw Exception('Failed to decode image');

  for (final box in payload.boxes) {
    final x = box[0].clamp(0, image.width - 1);
    final y = box[1].clamp(0, image.height - 1);
    final w = min(box[2], image.width - x);
    final h = min(box[3], image.height - y);
    if (w <= 0 || h <= 0) continue;

    final face = img.copyCrop(image, x: x, y: y, width: w, height: h);
    img.grayscale(face);
    img.compositeImage(image, face, dstX: x, dstY: y);
  }

  return img.encodeJpg(image, quality: 90);
}

// ---------------------------------------------------------------------------
// Processor
// ---------------------------------------------------------------------------

/// Handles ML Kit face detection and the grayscale compositing pipeline.
class FaceProcessor {
  /// Runs ML Kit [FaceDetector] and returns bounding boxes as `[x, y, w, h]`.
  Future<List<List<int>>> detect(String imagePath) async {
    final detector = FaceDetector(
      options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
    );

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final faces = await detector.processImage(inputImage);

      return faces.map((f) {
        final box = f.boundingBox;
        return [
          box.left.round(),
          box.top.round(),
          box.width.round(),
          box.height.round(),
        ];
      }).toList();
    } finally {
      await detector.close();
    }
  }

  /// Runs the full face pipeline (post-detection) and returns a [ProcessingRecord].
  Future<ProcessingRecord> process(
    String imagePath,
    Uint8List bytes,
    List<List<int>> faceRects, {
    required Stopwatch stopwatch,
    ProgressCallback? onProgress,
  }) async {
    // Heavy image work in a separate isolate
    onProgress?.call(
      0.5,
      'Applying Filter',
      'Converting faces to black & white',
    );
    _log.info('Starting isolate for face manipulation');

    final payload = _IsolatePayload(bytes, faceRects);
    final resultBytes = await Isolate.run(() => _processInIsolate(payload));

    // Save result + copy original
    onProgress?.call(
      0.85,
      'Saving Result',
      'Writing composite image to storage',
    );
    final resultFileName = await saveResult(
      resultBytes,
      prefix: 'face_result_',
    );
    final originalFileName = await copyToDocuments(imagePath);
    _log.info(
      'Result saved: $resultFileName, original copied: $originalFileName',
    );

    // Create history record
    stopwatch.stop();
    final resultFile = File('$docsDir/$resultFileName');
    final resultFileSize = await resultFile.length();
    _log.info(
      'Pipeline finished in ${stopwatch.elapsedMilliseconds}ms, '
      'result size: $resultFileSize bytes',
    );

    final record = ProcessingRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: ProcessingType.face,
      createdAt: DateTime.now(),
      originalPath: originalFileName,
      resultPath: resultFileName,
      metadata: {
        'faceCount': faceRects.length,
        'processingTimeMs': stopwatch.elapsedMilliseconds,
        'resultFileSize': resultFileSize,
      },
    );
    await Get.find<HistoryManager>().addRecord(record);

    onProgress?.call(1.0, 'Done', 'Processing complete');
    _log.info('Face processing complete — record ${record.id}');
    return record;
  }
}
