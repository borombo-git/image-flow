import 'package:flutter/material.dart';

import 'widgets/capture_option_tile.dart';

class CaptureBottomSheet extends StatelessWidget {
  const CaptureBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const CaptureBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          CaptureOptionTile(
            icon: Icons.camera_alt_outlined,
            title: 'Camera',
            subtitle: 'Take a new photo',
            onTap: () {
              // TODO: open camera
            },
          ),
          const SizedBox(height: 12),
          CaptureOptionTile(
            icon: Icons.photo_library_outlined,
            title: 'Photo Gallery',
            subtitle: 'Import from device',
            color: const Color(0xFF7C3AED),
            onTap: () {
              // TODO: open gallery
            },
          ),
        ],
      ),
    );
  }
}
