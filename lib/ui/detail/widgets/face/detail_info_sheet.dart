import 'package:flutter/material.dart';

import '../../../../common/theme/app_theme.dart';
import '../../../../common/widgets/scale_button.dart';
import '../../../../common/utils/format_utils.dart';
import '../../../../model/processing_record.dart';
import '../detail_stat_card.dart';

/// Bottom persistent white sheet with record info, stats, and save button.
class DetailInfoSheet extends StatelessWidget {
  const DetailInfoSheet({
    super.key,
    required this.record,
    required this.onSave,
  });

  final ProcessingRecord record;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final metadata = record.metadata ?? {};
    final isFace = record.type == ProcessingType.face;
    final processingTimeMs = metadata['processingTimeMs'] as int? ?? 0;
    final resultFileSize = metadata['resultFileSize'] as int? ?? 0;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDragHandle(),
            const SizedBox(height: 16),
            _buildTitleRow(),
            const SizedBox(height: 4),
            Text(formatDateLong(record.createdAt), style: kFontCaption),
            const SizedBox(height: 16),
            _buildStats(
              isFace: isFace,
              fileSize: resultFileSize,
              metadata: metadata,
              processingTimeMs: processingTimeMs,
            ),
            const SizedBox(height: 20),
            _buildSaveButton(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildTitleRow() {
    final isFace = record.type == ProcessingType.face;
    final title = isFace ? 'Portrait Scan' : 'Document Scan';
    final badgeLabel = isFace ? 'FACE' : 'DOC';
    final badgeColor = isFace ? kColorBadgeFace : kColorBadgeDoc;

    return Row(
      children: [
        Text(title, style: kFontH2),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            border: Border.all(color: badgeColor),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            badgeLabel,
            style: TextStyle(
              fontFamily: kSatoshi,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: badgeColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats({
    required bool isFace,
    required int fileSize,
    required Map<String, dynamic> metadata,
    required int processingTimeMs,
  }) {
    final middleIcon = isFace ? Icons.face_outlined : Icons.article_outlined;
    final middleLabel = isFace ? 'FACES' : 'BLOCKS';
    final middleValue = isFace
        ? '${metadata['faceCount'] as int? ?? 0}'
        : '${metadata['textBlockCount'] as int? ?? 0}';

    return Row(
      children: [
        DetailStatCard(
          icon: Icons.straighten,
          label: 'SIZE',
          value: formatFileSize(fileSize),
        ),
        const SizedBox(width: 10),
        DetailStatCard(
          icon: middleIcon,
          label: middleLabel,
          value: middleValue,
        ),
        const SizedBox(width: 10),
        DetailStatCard(
          icon: Icons.timer_outlined,
          label: 'TIME',
          value: formatDuration(processingTimeMs),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return ScaleOnPress(
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: kColorFont,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: kFontBodyBold,
          ),
          icon: const Icon(Icons.download, size: 20),
          label: const Text('Save to Photos'),
        ),
      ),
    );
  }
}
