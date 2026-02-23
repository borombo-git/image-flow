import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/theme/app_theme.dart';

/// Confirmation dialog before removing a page from the document collector.
class RemovePageDialog {
  RemovePageDialog._();

  static void show({required int pageNumber, required VoidCallback onConfirm}) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove page?', style: kFontH3),
        content: Text(
          'Page $pageNumber will be permanently removed.',
          style: const TextStyle(
            fontFamily: kSatoshi,
            color: kColorFontSecondary,
            fontSize: kSizeBody,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              onConfirm();
            },
            child: Text('Remove', style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }
}
