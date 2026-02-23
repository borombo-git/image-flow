import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../common/theme/app_theme.dart';
import '../../../../common/utils/format_utils.dart';
import '../../../../common/utils/logger.dart';
import '../../../../common/utils/path_utils.dart';
import '../../../../common/widgets/scale_button.dart';
import '../../../../model/processing_record.dart';
import '../../../home/home_controller.dart';
import '../../../home/widgets/delete_record_sheet.dart';
import '../detail_stat_card.dart';
import 'extracted_text_card.dart';

const _log = AppLogger('🔍', 'DETAIL');
final _scanDateFormat = DateFormat('yyyyMMdd');

/// Detail view for document processing records.
class DocumentDetailView extends StatelessWidget {
  const DocumentDetailView({super.key, required this.record});

  final ProcessingRecord record;

  @override
  Widget build(BuildContext context) {
    final metadata = record.metadata ?? {};
    final pdfPath = metadata['pdfPath'] as String?;
    final pdfFileSize = metadata['pdfFileSize'] as int? ?? 0;
    final textBlockCount = metadata['textBlockCount'] as int? ?? 0;
    final extractedText = metadata['extractedText'] as String?;
    final scanName = 'Scan_${_scanDateFormat.format(record.createdAt)}.pdf';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: Get.back,
          ),
          title: const Text('Document', style: kFontH2),
          centerTitle: true,
          actions: [
            _buildShareButton(context, pdfPath),
            _buildDeleteButton(context),
            const SizedBox(width: 4),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            children: [
              _buildPdfRow(scanName, pdfFileSize, pdfPath),
              const SizedBox(height: 20),
              _buildStats(pdfFileSize, textBlockCount),
              if (extractedText != null && extractedText.isNotEmpty) ...[
                const SizedBox(height: 20),
                ExtractedTextCard(text: extractedText),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareButton(BuildContext context, String? pdfPath) {
    return IconButton(
      onPressed: pdfPath != null ? () => _sharePdf(context, pdfPath) : null,
      icon: const Icon(Icons.share_outlined, size: 20),
      tooltip: 'Share PDF',
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return IconButton(
      onPressed: () => _delete(context),
      icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
      tooltip: 'Delete',
    );
  }

  Widget _buildPdfRow(String scanName, int pdfFileSize, String? pdfPath) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // PDF icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: kColorPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: kColorPrimary,
              size: 24,
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
          const SizedBox(width: 8),
          ScaleOnPress(
            child: GestureDetector(
              onTap: pdfPath != null ? () => _openPdf(pdfPath) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: kColorPrimary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Open',
                  style: TextStyle(
                    fontFamily: kSatoshi,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(int pdfFileSize, int textBlockCount) {
    final pageCount = record.metadata?['pageCount'] as int?;
    final showPageCount = pageCount != null && pageCount > 1;

    return Row(
      children: [
        DetailStatCard(
          icon: Icons.straighten,
          label: 'PDF SIZE',
          value: formatFileSize(pdfFileSize),
        ),
        const SizedBox(width: 10),
        if (showPageCount)
          DetailStatCard(
            icon: Icons.pages_outlined,
            label: 'PAGES',
            value: '$pageCount',
          )
        else
          DetailStatCard(
            icon: Icons.article_outlined,
            label: 'BLOCKS',
            value: '$textBlockCount',
          ),
        const SizedBox(width: 10),
        DetailStatCard(
          icon: Icons.timer_outlined,
          label: 'TIME',
          value: formatDuration(
            record.metadata?['processingTimeMs'] as int? ?? 0,
          ),
        ),
      ],
    );
  }

  Future<void> _openPdf(String pdfPath) async {
    _log.info('Opening PDF: $pdfPath');
    await OpenFilex.open(resolveDocPath(pdfPath));
  }

  Future<void> _sharePdf(BuildContext context, String pdfPath) async {
    _log.info('Sharing PDF: $pdfPath');
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : Rect.zero;

    await Share.shareXFiles([
      XFile(resolveDocPath(pdfPath)),
    ], sharePositionOrigin: origin);
  }

  void _delete(BuildContext context) {
    DeleteRecordSheet.show(
      context,
      onConfirm: () {
        Get.find<HomeController>().deleteRecord(record.id);
        _log.info('Record deleted: ${record.id}');
        Get.back();
      },
    );
  }
}
