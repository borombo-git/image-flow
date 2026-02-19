import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/exceptions/processing_exceptions.dart';
import '../../common/theme/app_theme.dart';
import '../../common/utils/logger.dart';
import '../../manager/image_processing_manager.dart';
import '../../routes/app_routes.dart';

const _log = AppLogger('⚙️', 'PROCESSING');

class ProcessingController extends GetxController {
  final _processingManager = Get.find<ImageProcessingManager>();

  final imagePath = ''.obs;
  final currentStep = 'Analyzing Image...'.obs;
  final stepDescription = 'Detecting content type'.obs;
  final progress = 0.0.obs;
  final hasError = false.obs;

  @override
  void onInit() {
    super.onInit();
    imagePath.value = Get.arguments as String? ?? '';
    _log.info('Started with image: ${imagePath.value}');
  }

  @override
  void onReady() {
    super.onReady();
    _startProcessing();
  }

  Future<void> _startProcessing() async {
    if (imagePath.value.isEmpty) {
      _log.error('No image path provided');
      Get.back();
      return;
    }

    try {
      final record = await _processingManager.processFaces(
        imagePath.value,
        onProgress: (p, step, description) {
          _log.info('Progress: ${(p * 100).toInt()}% — $step');
          progress.value = p;
          currentStep.value = step;
          stepDescription.value = description;
        },
      );

      _log.info('Processing complete — navigating to result');
      Get.offNamed(AppRoutes.result, arguments: record);
    } on NoFacesDetectedException {
      _log.info('No faces found — showing error dialog');
      _showErrorDialog(
        title: 'No Faces Found',
        message:
            'Could not detect any faces in this image. Try a different photo.',
      );
    } catch (e, stack) {
      _log.error('Processing failed', e, stack);
      _showErrorDialog(
        title: 'Processing Failed',
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  void _showErrorDialog({required String title, required String message}) {
    hasError.value = true;
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: kFontH3),
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: kSatoshi,
            color: kColorFontSecondary,
            fontSize: kSizeBody,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(); // close dialog
              Get.back(); // go back to home
            },
            child: const Text('OK'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
