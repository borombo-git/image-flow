import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../home_controller.dart';
import 'delete_record_sheet.dart';
import 'history_card.dart';

/// 2-column grid of history cards with long-press delete.
class HistoryGrid extends StatelessWidget {
  const HistoryGrid({super.key, required this.controller});

  final HomeController controller;

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

          return HistoryCard(
            key: ValueKey(record.id),
            record: record,
            onTap: () => Get.toNamed(
              AppRoutes.result,
              arguments: record,
            ),
            onLongPress: () {
              HapticFeedback.mediumImpact();
              DeleteRecordSheet.show(
                context,
                onConfirm: () => controller.deleteRecord(record.id),
              );
            },
          );
        },
      ),
    );
  }
}
