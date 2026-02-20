import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../model/processing_record.dart';
import 'widgets/document_result_view.dart';
import 'widgets/face_result_view.dart';

/// Routes to the appropriate result view based on processing type.
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final record = Get.arguments as ProcessingRecord?;
    if (record == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => Get.back());
      return const SizedBox.shrink();
    }

    return record.type == ProcessingType.face
        ? FaceResultView(record: record)
        : DocumentResultView(record: record);
  }
}
