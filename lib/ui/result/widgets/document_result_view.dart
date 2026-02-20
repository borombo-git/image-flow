import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';

import '../../../common/theme/app_theme.dart';
import '../../../common/utils/format_utils.dart';
import '../../../common/utils/path_utils.dart';
import '../../../model/processing_record.dart';

final _scanDateFormat = DateFormat('yyyyMMdd');

/// Document result screen matching the "PDF Created" mockup.
class DocumentResultView extends StatelessWidget {
  const DocumentResultView({super.key, required this.record});

  final ProcessingRecord record;

  @override
  Widget build(BuildContext context) {
    final metadata = record.metadata ?? {};
    final pdfPath = metadata['pdfPath'] as String?;
    final pdfFileSize = metadata['pdfFileSize'] as int? ?? 0;
    final scanName = 'Scan_${_scanDateFormat.format(record.createdAt)}.pdf';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: Get.back,
        ),
        title: const Text('PDF Created', style: kFontH2),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    _buildCard(scanName, pdfFileSize),
                    const SizedBox(height: 32),
                    _buildMessage(),
                    const Spacer(flex: 3),
                  ],
                ),
              ),
            ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  Divider(
                    height: 1,
                    color: kColorFontSecondary.withValues(alpha: 0.15),
                  ),
                  const SizedBox(height: 16),
                  _buildOpenPdfButton(pdfPath),
                  const SizedBox(height: 12),
                  _buildDoneButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String scanName, int pdfFileSize) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kColorFontSecondary.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image + checkmark
          Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.file(
                      File(resolveDocPath(record.resultPath)),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: kColorFontSecondary,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Green checkmark badge
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: kColorSuccess,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),

          // PDF file info row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // PDF icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: kColorDangerLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    color: kColorDanger,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scanName,
                        style: kFontBodyBold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${formatFileSize(pdfFileSize)} · ${formatDate(record.createdAt)}',
                        style: kFontCaption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage() {
    return Column(
      children: [
        const Text('Ready to share', style: kFontH2),
        const SizedBox(height: 8),
        Text(
          'Your document has been optimized.',
          style: kFontBody.copyWith(color: kColorFontSecondary),
        ),
      ],
    );
  }

  Widget _buildOpenPdfButton(String? pdfPath) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: pdfPath != null ? () => _openPdf(pdfPath) : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: kColorFont,
          side: BorderSide(color: kColorFontSecondary.withValues(alpha: 0.25)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: kFontBodyBold,
        ),
        icon: const Icon(Icons.open_in_new, size: 20),
        label: const Text('Open PDF'),
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

  Future<void> _openPdf(String pdfPath) async {
    await OpenFilex.open(resolveDocPath(pdfPath));
  }
}
