import 'dart:io';

import 'package:flutter/material.dart';

import '../../../common/theme/app_theme.dart';
import '../../../common/utils/format_utils.dart';
import '../../../common/utils/path_utils.dart';
import '../../../model/processing_record.dart';

/// A single history grid card showing the result image, type badge, and date.
class HistoryCard extends StatelessWidget {
  const HistoryCard({
    super.key,
    required this.record,
    required this.onTap,
    this.onLongPress,
  });

  final ProcessingRecord record;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(),
            _buildDate(),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Expanded(
      child: Stack(
        children: [
          // Result image
          Hero(
            tag: 'record_${record.id}',
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
                bottom: Radius.circular(8),
              ),
              child: SizedBox.expand(
                child: Image.file(
                  File(resolveDocPath(record.resultPath)),
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => Container(
                    color: kColorBackground,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: kColorFontSecondary,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Type badge
          Positioned(
            top: 8,
            right: 8,
            child: _buildBadge(),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge() {
    final isFace = record.type == ProcessingType.face;
    final color = isFace ? kColorBadgeFace : kColorBadgeDoc;
    final label = isFace ? '👤 FACE' : '📄 DOC';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: kSatoshi,
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDate() {
    final formatted = formatDate(record.createdAt);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Text(
        formatted,
        style: kFontCaption,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
