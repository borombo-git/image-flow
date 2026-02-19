import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';

import '../../../common/utils/path_utils.dart';
import '../../../model/processing_record.dart';
import '../../../routes/app_routes.dart';
import '../home_controller.dart';
import 'delete_record_sheet.dart';
import 'history_card.dart';

/// 2-column grid of history cards with long-press delete.
class HistoryGrid extends StatelessWidget {
  const HistoryGrid({super.key, required this.controller});

  final HomeController controller;

  void _onTap(ProcessingRecord record) {
    if (record.type == ProcessingType.document) {
      final pdfPath = (record.metadata ?? {})['pdfPath'] as String?;
      if (pdfPath != null) {
        OpenFilex.open(resolveDocPath(pdfPath));
        return;
      }
    }
    Get.toNamed(AppRoutes.detail, arguments: record);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 3 / 4,
        ),
        itemCount: controller.records.length,
        itemBuilder: (context, index) {
          final record = controller.records[index];
          final isDeleting = controller.deletingId.value == record.id;

          return AnimatedScale(
            scale: isDeleting ? 0.85 : 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: AnimatedOpacity(
              opacity: isDeleting ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: HistoryCard(
                key: ValueKey(record.id),
                record: record,
                onTap: () => _onTap(record),
                onLongPress: () {
                  HapticFeedback.mediumImpact();
                  DeleteRecordSheet.show(
                    context,
                    onConfirm: () => controller.deleteRecord(record.id),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
