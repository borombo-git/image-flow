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
  final List<int> cropBounds; // [x, y, w, h]

  const _IsolatePayload(this.bytes, this.cropBounds);
}

/// Top-level function for [Isolate.run].
/// Decodes → bakes orientation → crops to bounds → enhances contrast/saturation → JPEG.
Uint8List _processInIsolate(_IsolatePayload payload) {
  final decoded = img.decodeImage(payload.bytes);
  if (decoded == null) throw Exception('Failed to decode image');

  final image = img.bakeOrientation(decoded);

  // Clamp crop bounds to image dimensions
  final x = payload.cropBounds[0].clamp(0, image.width - 1);
  final y = payload.cropBounds[1].clamp(0, image.height - 1);
  final w = min(payload.cropBounds[2], image.width - x);
  final h = min(payload.cropBounds[3], image.height - y);

  final cropped = (w > 0 && h > 0)
      ? img.copyCrop(image, x: x, y: y, width: w, height: h)
      : image;

  // Enhance for readability: boost contrast, slight desaturation, tiny brightness lift
  final enhanced = img.adjustColor(
    cropped,
    contrast: 1.4,
    saturation: 0.4,
    brightness: 1.05,
  );

  return img.encodeJpg(enhanced, quality: 92);
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
    // Estimate document bounds from text blocks
    onProgress?.call(0.3, 'Detecting Bounds', 'Estimating document area');
    final cropBounds = _estimateDocumentBounds(textBlocks);
    _log.info('Document bounds: $cropBounds');

    // Crop + enhance in isolate
    onProgress?.call(0.45, 'Enhancing Document', 'Cropping and improving readability');
    _log.info('Starting isolate for document enhancement');

    final payload = _IsolatePayload(bytes, cropBounds);
    final resultBytes = await Isolate.run(() => _processInIsolate(payload));

    // Save enhanced image + copy original
    onProgress?.call(0.7, 'Saving Image', 'Writing enhanced image to storage');
    final resultFileName = await saveResult(resultBytes, prefix: 'doc_result_');
    final originalFileName = await copyToDocuments(imagePath);
    _log.info('Result saved: $resultFileName, original copied: $originalFileName');

    // Generate PDF
    onProgress?.call(0.8, 'Creating PDF', 'Generating document PDF');
    final pdfFileName = await _generatePdf(resultBytes);
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

  /// Computes the union bounding box of all text blocks + 5% padding.
  /// Returns `[x, y, w, h]` in pixel coordinates.
  List<int> _estimateDocumentBounds(List<TextBlock> blocks) {
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

    // 5% padding on each side
    final w = right - left;
    final h = bottom - top;
    final padX = w * 0.05;
    final padY = h * 0.05;

    return [
      (left - padX).round(),
      (top - padY).round(),
      (w + padX * 2).round(),
      (h + padY * 2).round(),
    ];
  }

  /// Generates a single-page A4 PDF containing the enhanced document image.
  /// Returns the PDF filename (stored in docs directory).
  Future<String> _generatePdf(Uint8List imageBytes) async {
    final pdf = pw.Document();

    final image = pw.MemoryImage(imageBytes);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Center(
          child: pw.Image(image, fit: pw.BoxFit.contain),
        ),
      ),
    );

    final fileName = 'doc_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('$docsDir/$fileName');
    await file.writeAsBytes(await pdf.save());
    _log.info('PDF saved: $fileName');
    return fileName;
  }
}
