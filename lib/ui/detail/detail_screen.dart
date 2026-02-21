import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../model/processing_record.dart';
import 'widgets/document_detail_view.dart';
import 'widgets/face_detail_view.dart';

/// Routes to the appropriate detail view based on processing type.
class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final record = Get.arguments as ProcessingRecord?;
    if (record == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => Get.back());
      return const SizedBox.shrink();
    }

    return record.type == ProcessingType.face
        ? FaceDetailView(record: record)
        : DocumentDetailView(record: record);
  }
}
