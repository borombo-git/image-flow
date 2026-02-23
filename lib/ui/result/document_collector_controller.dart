import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../common/exceptions/processing_exceptions.dart';
import '../../common/utils/logger.dart';
import '../../common/utils/path_utils.dart';
import '../../common/utils/snackbar_utils.dart';
import '../../manager/history_manager.dart';
import '../../manager/image_processing_manager.dart';
import '../../model/document_page.dart';
import '../../model/processing_record.dart';
import '../../routes/app_routes.dart';
import '../capture/capture_bottom_sheet.dart';
import 'widgets/document/remove_page_dialog.dart';

const _log = AppLogger('📑', 'COLLECTOR');

/// Manages multi-page document collection on the result screen.
///
/// Scoped controller — lives only during the result screen session.
/// Handles page add/remove/reorder and final PDF generation + Hive save.
class DocumentCollectorController extends GetxController {
  final _processingManager = Get.find<ImageProcessingManager>();
  final _documentProcessor = Get.find<ImageProcessingManager>().documentProcessor;

  final pages = <DocumentPage>[].obs;
  final selectedIndex = 0.obs;
  final isProcessing = false.obs;
  final processingStep = ''.obs;

  bool _saved = false;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is DocumentPage) {
      pages.add(args);
      _log.info('Initialized with first page: ${args.enhancedImagePath}');
    }
  }

  @override
  void onClose() {
    // Clean up temp files if the user didn't save
    if (!_saved && pages.isNotEmpty) {
      _log.info('Controller disposed without saving — cleaning up temp files');
      discardAll();
    }
    super.onClose();
  }

  void selectPage(int index) {
    if (index >= 0 && index < pages.length) {
      selectedIndex.value = index;
    }
  }

  /// Shows a confirmation dialog, then removes the page if confirmed.
  void removePage(int index) {
    if (pages.length <= 1) return;
    RemovePageDialog.show(
      pageNumber: index + 1,
      onConfirm: () => _doRemovePage(index),
    );
  }

  void _doRemovePage(int index) {
    if (index >= pages.length || pages.length <= 1) return;
    _log.info('Removing page $index');

    final removed = pages.removeAt(index);
    _deletePageFiles(removed);

    // Adjust selection to stay in bounds / follow removed context
    if (selectedIndex.value >= pages.length) {
      selectedIndex.value = pages.length - 1;
    } else if (selectedIndex.value > index) {
      selectedIndex.value--;
    }
  }

  void reorderPages(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    // ReorderableListView gives newIndex adjusted for removal
    final adjustedNew = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final page = pages.removeAt(oldIndex);
    pages.insert(adjustedNew, page);

    // Follow the selected page
    if (selectedIndex.value == oldIndex) {
      selectedIndex.value = adjustedNew;
    } else if (oldIndex < selectedIndex.value &&
        adjustedNew >= selectedIndex.value) {
      selectedIndex.value--;
    } else if (oldIndex > selectedIndex.value &&
        adjustedNew <= selectedIndex.value) {
      selectedIndex.value++;
    }
    _log.info('Reordered page $oldIndex → $adjustedNew');
  }

  /// Opens the capture sheet and processes the picked image as a new page.
  void addPage(BuildContext context) {
    CaptureBottomSheet.show(context, onImagePicked: _processNewPage);
  }

  Future<void> _processNewPage(String imagePath) async {
    if (isProcessing.value) return;
    _log.info('Processing additional page: $imagePath');
    isProcessing.value = true;
    processingStep.value = 'Loading Image';

    try {
      final page = await _processingManager.processDocumentPage(
        imagePath,
        onProgress: (_, step, __) => processingStep.value = step,
      );

      pages.add(page);
      selectedIndex.value = pages.length - 1;
      _log.info('Page added — now ${pages.length} page(s)');
    } on NoContentDetectedException {
      _log.info('Add page rejected — no document content');
      showErrorSnackbar(
        'Not a Document',
        'Could not detect document text in this image.',
      );
    } catch (e, stack) {
      _log.error('Add page failed', e, stack);
      showErrorSnackbar('Error', 'Failed to process page. Please try again.');
    } finally {
      isProcessing.value = false;
      processingStep.value = '';
    }
  }

  /// Generates the multi-page PDF, saves the record to Hive, and navigates home.
  Future<void> saveDocument() async {
    if (isProcessing.value) return;
    _log.info('Saving document with ${pages.length} page(s)');
    isProcessing.value = true;
    processingStep.value = 'Creating PDF';

    try {
      final stopwatch = Stopwatch()..start();

      final pdfFileName = await _documentProcessor.generatePdf(pages.toList());
      final pdfFile = File('$docsDir/$pdfFileName');
      final pdfFileSize = await pdfFile.length();

      stopwatch.stop();
      _log.info('PDF generated: $pdfFileName ($pdfFileSize bytes)');

      final firstPage = pages.first;
      final resultFile = File('$docsDir/${firstPage.enhancedImagePath}');
      final resultFileSize = await resultFile.length();

      // Aggregate extracted text
      final extractedText = pages.length == 1
          ? firstPage.extractedText
          : pages
                .asMap()
                .entries
                .map(
                  (e) => '--- Page ${e.key + 1} ---\n${e.value.extractedText}',
                )
                .join('\n\n');

      final totalBlocks = pages.fold<int>(
        0,
        (sum, p) => sum + p.textBlockCount,
      );

      final record = ProcessingRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: ProcessingType.document,
        createdAt: DateTime.now(),
        originalPath: firstPage.originalImagePath,
        resultPath: firstPage.enhancedImagePath,
        metadata: {
          'pageCount': pages.length,
          'textBlockCount': totalBlocks,
          'processingTimeMs': stopwatch.elapsedMilliseconds,
          'resultFileSize': resultFileSize,
          'pdfPath': pdfFileName,
          'pdfFileSize': pdfFileSize,
          'extractedText': extractedText,
          'pageResultPaths': pages.map((p) => p.enhancedImagePath).toList(),
          'pageOriginalPaths': pages.map((p) => p.originalImagePath).toList(),
        },
      );

      await Get.find<HistoryManager>().addRecord(record);
      _saved = true;
      HapticFeedback.mediumImpact();
      _log.info('Document saved — record ${record.id}');

      Get.offAllNamed(AppRoutes.home);
    } catch (e, stack) {
      _log.error('Save document failed', e, stack);
      showErrorSnackbar('Error', 'Failed to save document. Please try again.');
    } finally {
      isProcessing.value = false;
      processingStep.value = '';
    }
  }

  /// Deletes all temp files for pages that haven't been saved.
  void discardAll() {
    _log.info('Discarding ${pages.length} page(s)');
    for (final page in pages) {
      _deletePageFiles(page);
    }
    pages.clear();
  }

  void _deletePageFiles(DocumentPage page) {
    _tryDelete(page.enhancedImagePath);
    _tryDelete(page.originalImagePath);
  }

  Future<void> _tryDelete(String fileName) async {
    try {
      final file = File(resolveDocPath(fileName));
      if (await file.exists()) await file.delete();
    } catch (e) {
      _log.error('Failed to delete temp file: $fileName', e);
    }
  }
}
