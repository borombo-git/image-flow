import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/theme/app_theme.dart';
import '../../../common/widgets/bottom_sheet_container.dart';

/// Confirmation bottom sheet for deleting a history record.
class DeleteRecordSheet extends StatelessWidget {
  const DeleteRecordSheet({super.key, required this.onConfirm});

  final VoidCallback onConfirm;

  static void show(BuildContext context, {required VoidCallback onConfirm}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => DeleteRecordSheet(onConfirm: onConfirm),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Delete this record?', style: kFontH3),
          const SizedBox(height: 8),
          const Text(
            'This action cannot be undone.',
            style: TextStyle(
              fontFamily: kSatoshi,
              color: kColorFontSecondary,
              fontSize: kSizeBody,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Get.back();
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade500,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: kFontBodyBold,
              ),
              child: const Text('Delete'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: Get.back,
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: kFontBodyMedium,
              ),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }
}
