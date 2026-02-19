import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/theme/app_theme.dart';
import '../../../common/utils/format_utils.dart';
import '../../../model/processing_record.dart';
import 'before_after_comparison.dart';
import 'stats_row.dart';

/// Face result UI with before/after comparison, stats, and done button.
class FaceResultView extends StatelessWidget {
  const FaceResultView({super.key, required this.record});

  final ProcessingRecord record;

  @override
  Widget build(BuildContext context) {
    final metadata = record.metadata ?? {};
    final faceCount = metadata['faceCount'] as int? ?? 0;
    final processingTimeMs = metadata['processingTimeMs'] as int? ?? 0;
    final resultFileSize = metadata['resultFileSize'] as int? ?? 0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: Get.back,
        ),
        title: const Text('Face Result', style: kFontH2),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Expanded(
                child: BeforeAfterComparison(
                  originalPath: record.originalPath,
                  resultPath: record.resultPath,
                ),
              ),
              const SizedBox(height: 24),
              StatsRow(
                stats: [
                  (label: 'Processing Time', value: formatDuration(processingTimeMs)),
                  (label: 'Features', value: '$faceCount Face${faceCount == 1 ? '' : 's'}'),
                  (label: 'File Size', value: formatFileSize(resultFileSize)),
                ],
              ),
              const Spacer(),
              _buildDoneButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoneButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: Get.back,
        style: ElevatedButton.styleFrom(
          backgroundColor: kColorPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: kFontBodyBold,
        ),
        child: const Text('Done'),
      ),
    );
  }
}
