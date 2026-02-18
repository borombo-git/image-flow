import 'package:flutter/material.dart';
import 'package:image_flow/common/theme/app_theme.dart';

class HomeEmptyState extends StatelessWidget {
  const HomeEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(),
            const SizedBox(height: 24),
            const Text('No scans yet', style: kFontH2),
            const SizedBox(height: 8),
            const Text(
              "Tap the camera button to start. We'll automatically detect faces or documents for you.",
              style: TextStyle(
                fontFamily: kSatoshi,
                color: kColorFontSecondary,
                fontSize: kSizeBody,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: kColorPrimary.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.photo_library_outlined,
            size: 44,
            color: kColorPrimary,
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: kColorPrimary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, size: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
