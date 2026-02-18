import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../common/utils/logger.dart';
import '../../common/widgets/bottom_sheet_container.dart';
import '../../routes/app_routes.dart';
import 'widgets/capture_option_tile.dart';

const _log = AppLogger('📷', 'CAPTURE');

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
    return BottomSheetContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CaptureOptionTile(
            icon: Icons.camera_alt_outlined,
            title: 'Camera',
            subtitle: 'Take a new photo',
            onTap: () => _pickImage(ImageSource.camera),
          ),
          const SizedBox(height: 12),
          CaptureOptionTile(
            icon: Icons.photo_library_outlined,
            title: 'Photo Gallery',
            subtitle: 'Import from device',
            color: const Color(0xFF7C3AED),
            onTap: () => _pickImage(ImageSource.gallery),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    _log.info('Picking image from ${source.name}');
    // Close bottom sheet first so the picker presents full-screen from root
    Get.back();
    try {
      final file = await ImagePicker().pickImage(source: source);
      if (file == null) {
        _log.info('Selection cancelled');
        return;
      }
      _log.info('Image selected: ${file.path}');
      Get.toNamed(AppRoutes.processing, arguments: file.path);
    } on PlatformException catch (e) {
      _log.error('Error: ${e.message}', e);
      Get.snackbar(
        'Error',
        e.message ?? 'Could not access the selected source',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    }
  }
}
