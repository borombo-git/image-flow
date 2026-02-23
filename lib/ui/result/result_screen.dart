import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../model/document_page.dart';
import '../../model/processing_record.dart';
import 'document_collector_controller.dart';
import 'widgets/document/document_result_view.dart';
import 'widgets/face/face_result_view.dart';

/// Routes to the appropriate result view based on argument type.
///
/// - [ProcessingRecord] with face type → [FaceResultView]
/// - [DocumentPage] → initializes collector + [DocumentResultView]
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;

    // Face result — already saved to Hive by the processor
    if (args is ProcessingRecord && args.type == ProcessingType.face) {
      return FaceResultView(record: args);
    }

    // Document result — enter multi-page collection flow
    if (args is DocumentPage) {
      final collector = Get.find<DocumentCollectorController>();
      collector.initWithFirstPage(args);
      return const DocumentResultView();
    }

    // Fallback — shouldn't happen
    WidgetsBinding.instance.addPostFrameCallback((_) => Get.back());
    return const SizedBox.shrink();
  }
}
