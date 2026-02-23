import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/theme/app_theme.dart';
import '../../../../common/widgets/scale_button.dart';
import '../../document_collector_controller.dart';
import 'add_page_loading_overlay.dart';
import 'page_main_preview.dart';
import 'page_thumbnail_strip.dart';

/// Multi-page document result view.
///
/// Shows a thumbnail strip, main preview, and Add Page / Done buttons.
/// Reads all state from [DocumentCollectorController].
class DocumentResultView extends StatelessWidget {
  const DocumentResultView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DocumentCollectorController>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showDiscardDialog(controller);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _showDiscardDialog(controller),
          ),
          title: Obx(
            () => Text(
              '${controller.pages.length} Page${controller.pages.length == 1 ? '' : 's'}',
              style: kFontH2,
            ),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  const PageThumbnailStrip(),
                  const SizedBox(height: 16),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: PageMainPreview(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildBottomButtons(context, controller),
                ],
              ),
            ),
            const Positioned.fill(child: AddPageLoadingOverlay()),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons(
    BuildContext context,
    DocumentCollectorController controller,
  ) {
    return Obx(() {
      final busy = controller.isProcessing.value;

      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          children: [
            Divider(
              height: 1,
              color: kColorFontSecondary.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 16),
            // Add Page button
            ScaleOnPress(
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: busy ? null : () => controller.addPage(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kColorFont,
                    side: BorderSide(
                      color: kColorFontSecondary.withValues(alpha: 0.25),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: kFontBodyBold,
                  ),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add Page'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Done button
            ScaleOnPress(
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: busy ? null : controller.saveDocument,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kColorPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: kFontBodyBold,
                  ),
                  child: const Text('Done'),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _showDiscardDialog(DocumentCollectorController controller) {
    final pageCount = controller.pages.length;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Discard document?', style: kFontH3),
        content: Text(
          'You have $pageCount scanned page${pageCount == 1 ? '' : 's'} '
          "that haven't been saved.",
          style: const TextStyle(
            fontFamily: kSatoshi,
            color: kColorFontSecondary,
            fontSize: kSizeBody,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: Get.back, // close dialog
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.discardAll();
              Get.back(); // close dialog
              Get.back(); // go back to home
            },
            child: Text(
              'Discard',
              style: TextStyle(color: Colors.red.shade400),
            ),
          ),
        ],
      ),
    );
  }
}
