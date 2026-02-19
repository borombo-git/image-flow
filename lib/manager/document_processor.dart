import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../common/utils/logger.dart';
import '../common/utils/path_utils.dart';
import '../model/processing_record.dart';
import 'history_manager.dart';
import 'image_processing_manager.dart';

const _log = AppLogger('📄', 'DOCUMENT');

// ---------------------------------------------------------------------------
// Isolate
// ---------------------------------------------------------------------------

class _IsolatePayload {
  final Uint8List bytes;

  /// Seed region from text block union: [x, y, w, h].
  /// Used as starting point for luminance-based edge detection.
  final List<int> seedBounds;

  const _IsolatePayload(this.bytes, this.seedBounds);
}

/// Result from the isolate: enhanced JPEG bytes + detected document bounds.
class _IsolateResult {
  final Uint8List jpegBytes;
  final int cropWidth;
  final int cropHeight;

  const _IsolateResult(this.jpegBytes, this.cropWidth, this.cropHeight);
}

/// Top-level function for [Isolate.run].
///
/// Pipeline: decode pre-normalized image → luminance edge detection (using seed
/// bounds from text blocks) → crop to paper edges → contrast enhancement → JPEG.
/// Bytes are already EXIF-corrected by the orchestrator, so no bakeOrientation needed.
_IsolateResult _processInIsolate(_IsolatePayload payload) {
  final image = img.decodeImage(payload.bytes);
  if (image == null) throw Exception('Failed to decode image');

  // --- Edge detection: find paper boundaries via luminance scanning ---
  final seed = payload.seedBounds;
  final seedX = seed[0].clamp(0, image.width - 1);
  final seedY = seed[1].clamp(0, image.height - 1);
  final seedW = min(seed[2], image.width - seedX);
  final seedH = min(seed[3], image.height - seedY);

  // Sample the paper luminance from the center of the text area
  final paperLum = _sampleLuminance(
    image,
    seedX + seedW ~/ 2,
    seedY + seedH ~/ 2,
    min(seedW, seedH) ~/ 6,
  );

  // Threshold: paper edge is where luminance drops below 60% of paper brightness.
  // This accounts for shadows and slight color variations.
  final threshold = (paperLum * 0.60).round();

  // Scan outward from seed bounds to find actual paper edges
  final top = _scanUp(image, seedY, seedX, seedX + seedW, threshold);
  final bottom = _scanDown(image, seedY + seedH, seedX, seedX + seedW, threshold);
  final left = _scanLeft(image, seedX, seedY, seedY + seedH, threshold);
  final right = _scanRight(image, seedX + seedW, seedY, seedY + seedH, threshold);

  // Small fixed margin (8px) to avoid cutting right at the edge
  const margin = 8;
  final cropX = max(0, left - margin);
  final cropY = max(0, top - margin);
  final cropW = min(image.width - cropX, right - left + margin * 2);
  final cropH = min(image.height - cropY, bottom - top + margin * 2);

  final cropped = (cropW > 0 && cropH > 0)
      ? img.copyCrop(image, x: cropX, y: cropY, width: cropW, height: cropH)
      : image;

  // Enhance for readability
  final enhanced = img.adjustColor(
    cropped,
    contrast: 1.4,
    saturation: 0.4,
    brightness: 1.05,
  );

  return _IsolateResult(
    img.encodeJpg(enhanced, quality: 92),
    cropped.width,
    cropped.height,
  );
}

// ---------------------------------------------------------------------------
// Edge detection helpers (run inside isolate)
// ---------------------------------------------------------------------------

/// Samples average luminance in a square region around (cx, cy).
int _sampleLuminance(img.Image image, int cx, int cy, int radius) {
  int sum = 0;
  int count = 0;
  final r = max(radius, 4);

  for (int y = max(0, cy - r); y < min(image.height, cy + r); y++) {
    for (int x = max(0, cx - r); x < min(image.width, cx + r); x++) {
      sum += image.getPixel(x, y).luminance.round();
      count++;
    }
  }

  return count > 0 ? sum ~/ count : 128;
}

/// Average luminance of a horizontal row between [xStart] and [xEnd].
int _rowLuminance(img.Image image, int y, int xStart, int xEnd) {
  if (y < 0 || y >= image.height) return 0;
  final x0 = max(0, xStart);
  final x1 = min(image.width, xEnd);
  if (x1 <= x0) return 0;

  int sum = 0;
  // Sample every 4th pixel for speed on large images
  int count = 0;
  for (int x = x0; x < x1; x += 4) {
    sum += image.getPixel(x, y).luminance.round();
    count++;
  }
  return count > 0 ? sum ~/ count : 0;
}

/// Average luminance of a vertical column between [yStart] and [yEnd].
int _colLuminance(img.Image image, int x, int yStart, int yEnd) {
  if (x < 0 || x >= image.width) return 0;
  final y0 = max(0, yStart);
  final y1 = min(image.height, yEnd);
  if (y1 <= y0) return 0;

  int sum = 0;
  int count = 0;
  for (int y = y0; y < y1; y += 4) {
    sum += image.getPixel(x, y).luminance.round();
    count++;
  }
  return count > 0 ? sum ~/ count : 0;
}

/// Scans upward from [startY] until row luminance drops below [threshold].
int _scanUp(img.Image image, int startY, int xStart, int xEnd, int threshold) {
  for (int y = startY; y >= 0; y--) {
    if (_rowLuminance(image, y, xStart, xEnd) < threshold) return y + 1;
  }
  return 0;
}

/// Scans downward from [startY] until row luminance drops below [threshold].
int _scanDown(img.Image image, int startY, int xStart, int xEnd, int threshold) {
  for (int y = startY; y < image.height; y++) {
    if (_rowLuminance(image, y, xStart, xEnd) < threshold) return y - 1;
  }
  return image.height - 1;
}

/// Scans left from [startX] until column luminance drops below [threshold].
int _scanLeft(img.Image image, int startX, int yStart, int yEnd, int threshold) {
  for (int x = startX; x >= 0; x--) {
    if (_colLuminance(image, x, yStart, yEnd) < threshold) return x + 1;
  }
  return 0;
}

/// Scans right from [startX] until column luminance drops below [threshold].
int _scanRight(img.Image image, int startX, int yStart, int yEnd, int threshold) {
  for (int x = startX; x < image.width; x++) {
    if (_colLuminance(image, x, yStart, yEnd) < threshold) return x - 1;
  }
  return image.width - 1;
}

// ---------------------------------------------------------------------------
// Processor
// ---------------------------------------------------------------------------

/// Handles ML Kit text recognition, document enhancement, and PDF generation.
class DocumentProcessor {
  /// Runs ML Kit [TextRecognizer] and returns detected text blocks.
  Future<List<TextBlock>> detect(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final result = await recognizer.processImage(inputImage);
      return result.blocks;
    } finally {
      await recognizer.close();
    }
  }

  /// Runs the full document pipeline (post-detection) and returns a [ProcessingRecord].
  Future<ProcessingRecord> process(
    String imagePath,
    Uint8List bytes,
    List<TextBlock> textBlocks, {
    required Stopwatch stopwatch,
    ProgressCallback? onProgress,
  }) async {
    // Compute seed bounds from text blocks (union rect)
    onProgress?.call(0.3, 'Detecting Edges', 'Finding document boundaries');
    final seedBounds = _textBlockUnion(textBlocks);
    _log.info('Text block seed bounds: $seedBounds');

    // Edge detection + crop + enhance in isolate
    onProgress?.call(0.45, 'Enhancing Document', 'Cropping and improving readability');
    _log.info('Starting isolate for edge detection + enhancement');

    final payload = _IsolatePayload(bytes, seedBounds);
    final result = await Isolate.run(() => _processInIsolate(payload));
    _log.info(
      'Edge detection found document: ${result.cropWidth}x${result.cropHeight}',
    );

    // Save enhanced image + copy original
    onProgress?.call(0.7, 'Saving Image', 'Writing enhanced image to storage');
    final resultFileName =
        await saveResult(result.jpegBytes, prefix: 'doc_result_');
    final originalFileName = await copyToDocuments(imagePath);
    _log.info('Result saved: $resultFileName, original copied: $originalFileName');

    // Generate PDF sized to the document
    onProgress?.call(0.8, 'Creating PDF', 'Generating document PDF');
    final pdfFileName = await _generatePdf(
      result.jpegBytes,
      result.cropWidth,
      result.cropHeight,
    );
    final pdfFile = File('$docsDir/$pdfFileName');
    final pdfFileSize = await pdfFile.length();
    _log.info('PDF generated: $pdfFileName ($pdfFileSize bytes)');

    // Create history record
    stopwatch.stop();
    final resultFile = File('$docsDir/$resultFileName');
    final resultFileSize = await resultFile.length();
    _log.info(
      'Pipeline finished in ${stopwatch.elapsedMilliseconds}ms, '
      'result size: $resultFileSize bytes, pdf size: $pdfFileSize bytes',
    );

    final record = ProcessingRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: ProcessingType.document,
      createdAt: DateTime.now(),
      originalPath: originalFileName,
      resultPath: resultFileName,
      metadata: {
        'textBlockCount': textBlocks.length,
        'processingTimeMs': stopwatch.elapsedMilliseconds,
        'resultFileSize': resultFileSize,
        'pdfPath': pdfFileName,
        'pdfFileSize': pdfFileSize,
      },
    );
    await Get.find<HistoryManager>().addRecord(record);

    onProgress?.call(1.0, 'Done', 'Processing complete');
    _log.info('Document processing complete — record ${record.id}');
    return record;
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  /// Computes the union bounding box of all text blocks.
  /// Returns `[x, y, w, h]` — used as seed for luminance edge detection.
  List<int> _textBlockUnion(List<TextBlock> blocks) {
    double left = double.infinity;
    double top = double.infinity;
    double right = double.negativeInfinity;
    double bottom = double.negativeInfinity;

    for (final block in blocks) {
      final r = block.boundingBox;
      left = min(left, r.left);
      top = min(top, r.top);
      right = max(right, r.right);
      bottom = max(bottom, r.bottom);
    }

    return [
      left.round(),
      top.round(),
      (right - left).round(),
      (bottom - top).round(),
    ];
  }

  /// Generates a single-page PDF containing the enhanced document image.
  ///
  /// The page is sized to A4 proportions with minimal margins so the document
  /// fills the page. The image aspect ratio is preserved.
  Future<String> _generatePdf(
    Uint8List imageBytes,
    int imageWidth,
    int imageHeight,
  ) async {
    final pdf = pw.Document();
    final image = pw.MemoryImage(imageBytes);

    // A4 with small margins (12pt ≈ 4mm)
    const margin = 12.0;
    const format = PdfPageFormat.a4;
    final usableWidth = format.width - margin * 2;
    final usableHeight = format.height - margin * 2;

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(margin),
        build: (context) {
          // Scale image to fill the usable area while preserving aspect ratio
          final imageAspect = imageWidth / imageHeight;
          final pageAspect = usableWidth / usableHeight;

          final double imgWidth;
          final double imgHeight;

          if (imageAspect > pageAspect) {
            // Image is wider than page → fit to width
            imgWidth = usableWidth;
            imgHeight = usableWidth / imageAspect;
          } else {
            // Image is taller than page → fit to height
            imgHeight = usableHeight;
            imgWidth = usableHeight * imageAspect;
          }

          return pw.Center(
            child: pw.Image(
              image,
              width: imgWidth,
              height: imgHeight,
            ),
          );
        },
      ),
    );

    final fileName = 'doc_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('$docsDir/$fileName');
    await file.writeAsBytes(await pdf.save());
    _log.info('PDF saved: $fileName');
    return fileName;
  }
}
