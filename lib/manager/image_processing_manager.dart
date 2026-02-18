import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../common/exceptions/processing_exceptions.dart';
import '../common/utils/logger.dart';
import '../model/processing_record.dart';
import 'history_manager.dart';

const _log = AppLogger('🧠', 'PROCESSING');

/// Payload sent to the processing isolate.
class _IsolatePayload {
  final Uint8List bytes;
  final List<List<int>> boxes; // [x, y, w, h] per face

  const _IsolatePayload(this.bytes, this.boxes);
}

/// Top-level function for [Isolate.run].
/// Decodes image, bakes EXIF orientation, applies grayscale to each face region,
/// composites back, and returns JPEG bytes.
Uint8List _processImageInIsolate(_IsolatePayload payload) {
  final decoded = img.decodeImage(payload.bytes);
  if (decoded == null) throw Exception('Failed to decode image');

  final image = img.bakeOrientation(decoded);

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

/// Global singleton that runs image processing pipelines.
class ImageProcessingManager extends GetxController {
  /// Runs the face detection + grayscale pipeline.
  ///
  /// [onProgress] is called with (progress 0→1, step title, step description).
  /// Throws [NoFacesDetectedException] when no faces are found.
  Future<ProcessingRecord> processFaces(
    String imagePath, {
    void Function(double progress, String step, String description)? onProgress,
  }) async {
    // 1. Read image bytes
    onProgress?.call(0.0, 'Loading Image', 'Reading image from storage');
    _log.info('Reading image: $imagePath');
    final bytes = await File(imagePath).readAsBytes();

    // 2. ML Kit face detection (must run on main isolate — platform channels)
    onProgress?.call(0.2, 'Detecting Faces', 'Scanning for faces with ML Kit');
    _log.info('Running ML Kit face detection');
    final faceRects = await _detectFaces(imagePath);

    if (faceRects.isEmpty) {
      _log.info('No faces detected');
      throw const NoFacesDetectedException();
    }
    _log.info('Detected ${faceRects.length} face(s)');

    // 3. Heavy image work in a separate isolate
    onProgress?.call(0.5, 'Applying Filter', 'Converting faces to black & white');
    _log.info('Starting isolate for image manipulation');

    final payload = _IsolatePayload(bytes, faceRects);
    final resultBytes = await Isolate.run(() => _processImageInIsolate(payload));

    // 4. Save result to disk
    onProgress?.call(0.85, 'Saving Result', 'Writing composite image to storage');
    final resultPath = await _saveResult(resultBytes);
    _log.info('Result saved: $resultPath');

    // 5. Create history record
    final record = ProcessingRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: ProcessingType.face,
      createdAt: DateTime.now(),
      originalPath: imagePath,
      resultPath: resultPath,
      metadata: {'faceCount': faceRects.length},
    );
    await Get.find<HistoryManager>().addRecord(record);

    onProgress?.call(1.0, 'Done', 'Processing complete');
    _log.info('Face processing complete — record ${record.id}');
    return record;
  }

  /// Runs ML Kit [FaceDetector] and returns bounding boxes as `[x, y, w, h]`.
  Future<List<List<int>>> _detectFaces(String imagePath) async {
    final detector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
      ),
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

  /// Saves JPEG bytes to app documents directory.
  Future<String> _saveResult(Uint8List bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'face_result_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
