import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/theme/app_theme.dart';
import '../../../../common/utils/path_utils.dart';
import '../../document_collector_controller.dart';

/// Full preview of the currently selected page's enhanced image.
class PageMainPreview extends GetView<DocumentCollectorController> {
  const PageMainPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.pages.isEmpty) return const SizedBox.shrink();

      final index = controller.selectedIndex.value.clamp(
        0,
        controller.pages.length - 1,
      );
      final page = controller.pages[index];

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.file(
          File(resolveDocPath(page.enhancedImagePath)),
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey.shade100,
            child: const Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 48,
                color: kColorFontSecondary,
              ),
            ),
          ),
        ),
      );
    });
  }
}
