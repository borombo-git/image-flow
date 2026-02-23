import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/theme/app_theme.dart';
import '../../document_collector_controller.dart';

/// Semi-transparent overlay shown while processing an additional page.
class AddPageLoadingOverlay extends GetView<DocumentCollectorController> {
  const AddPageLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isProcessing.value) return const SizedBox.shrink();

      return Container(
        color: Colors.black45,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: kColorPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Obx(
                  () => Text(
                    controller.processingStep.value.isNotEmpty
                        ? controller.processingStep.value
                        : 'Processing...',
                    style: kFontBodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
