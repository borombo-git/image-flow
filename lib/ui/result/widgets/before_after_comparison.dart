import 'dart:io';

import 'package:flutter/material.dart';

import '../../../common/theme/app_theme.dart';
import '../../../common/utils/path_utils.dart';

/// Side-by-side before/after image comparison with labels.
class BeforeAfterComparison extends StatelessWidget {
  const BeforeAfterComparison({
    super.key,
    required this.originalPath,
    required this.resultPath,
  });

  final String originalPath;
  final String resultPath;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildLabels(),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildBeforeImage()),
              const SizedBox(width: 12),
              Expanded(child: _buildAfterImage()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabels() {
    final style = kFontCaption.copyWith(
      color: kColorPrimary,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
    );

    return Row(
      children: [
        Expanded(child: Center(child: Text('BEFORE', style: style))),
        const SizedBox(width: 12),
        Expanded(child: Center(child: Text('AFTER', style: style))),
      ],
    );
  }

  Widget _buildBeforeImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Image.file(
          File(resolveDocPath(originalPath)),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: kColorBackground,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    color: kColorFontSecondary,
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text('Unavailable', style: kFontCaption),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAfterImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(resolveDocPath(resultPath)),
              fit: BoxFit.cover,
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'B&W',
                  style: TextStyle(
                    fontFamily: kSatoshi,
                    color: Colors.white,
                    fontSize: kSizeCaption,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
