import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../common/utils/logger.dart';
import '../common/utils/path_utils.dart';
import '../model/document_page.dart';
import 'document_edge_detection.dart';
import 'image_processing_manager.dart';

const _log = AppLogger('📄', 'DOCUMENT');

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

  /// Processes a single page: edge detection + crop + enhance + save.
  ///
  /// Returns a [DocumentPage] without generating a PDF or saving to Hive.
  /// Used by both the single-shot [process()] and the multi-page collector.
  Future<DocumentPage> processPage(
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
    onProgress?.call(
      0.45,
      'Enhancing Document',
      'Cropping and improving readability',
    );
    _log.info('Starting isolate for edge detection + enhancement');

    final payload = EdgeDetectionPayload(bytes, seedBounds);
    final result = await Isolate.run(() => detectAndCrop(payload));
    _log.info(
      'Edge detection found document: ${result.cropWidth}x${result.cropHeight}',
    );

    // Save enhanced image + copy original
    onProgress?.call(0.7, 'Saving Image', 'Writing enhanced image to storage');
    final resultFileName = await saveResult(
      result.jpegBytes,
      prefix: 'doc_result_',
    );
    final originalFileName = await copyToDocuments(imagePath);
    _log.info(
      'Result saved: $resultFileName, original copied: $originalFileName',
    );

    final extractedText = textBlocks.map((b) => b.text).join('\n\n');
    _log.info('Page processed — ${extractedText.length} chars extracted');

    onProgress?.call(0.9, 'Almost Done', 'Finishing up');
    return DocumentPage(
      enhancedImagePath: resultFileName,
      originalImagePath: originalFileName,
      extractedText: extractedText,
      textBlockCount: textBlocks.length,
      cropWidth: result.cropWidth,
      cropHeight: result.cropHeight,
    );
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

  /// Generates a PDF with one A4 page per [DocumentPage].
  ///
  /// Each page is sized to A4 proportions with minimal margins.
  /// The image aspect ratio is preserved. Returns the PDF filename.
  Future<String> generatePdf(List<DocumentPage> pages) async {
    final pdf = pw.Document();

    // A4 with small margins (12pt ≈ 4mm)
    const margin = 12.0;
    const format = PdfPageFormat.a4;
    final usableWidth = format.width - margin * 2;
    final usableHeight = format.height - margin * 2;

    for (final page in pages) {
      final imageBytes = await File(
        '$docsDir/${page.enhancedImagePath}',
      ).readAsBytes();
      final image = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: format,
          margin: const pw.EdgeInsets.all(margin),
          build: (context) {
            final imageAspect = page.cropWidth / page.cropHeight;
            final pageAspect = usableWidth / usableHeight;

            final double imgWidth;
            final double imgHeight;

            if (imageAspect > pageAspect) {
              imgWidth = usableWidth;
              imgHeight = usableWidth / imageAspect;
            } else {
              imgHeight = usableHeight;
              imgWidth = usableHeight * imageAspect;
            }

            return pw.Center(
              child: pw.Image(image, width: imgWidth, height: imgHeight),
            );
          },
        ),
      );
    }

    final fileName = 'doc_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('$docsDir/$fileName');
    await file.writeAsBytes(await pdf.save());
    _log.info('PDF saved: $fileName (${pages.length} page(s))');
    return fileName;
  }
}
