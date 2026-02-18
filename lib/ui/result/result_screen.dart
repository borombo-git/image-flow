import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/theme/app_theme.dart';
import '../../model/processing_record.dart';
import '../../routes/app_routes.dart';

/// Minimal result screen — shows the processed image and face count.
/// Step 3 will add before/after comparison.
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final record = Get.arguments as ProcessingRecord;
    final faceCount = record.metadata?['faceCount'] as int? ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Result', style: kFontH2),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.offAllNamed(AppRoutes.home),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.file(
                    File(record.resultPath),
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Text(
                '$faceCount ${faceCount == 1 ? 'face' : 'faces'} detected',
                style: kFontCaption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
