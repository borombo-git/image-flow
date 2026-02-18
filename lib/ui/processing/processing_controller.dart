import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/exceptions/processing_exceptions.dart';
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

  @override
  void onInit() {
    super.onInit();
    imagePath.value = Get.arguments as String? ?? '';
    _log.info('Started with image: ${imagePath.value}');
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
          progress.value = p;
          currentStep.value = step;
          stepDescription.value = description;
        },
      );

      _log.info('Processing complete — navigating to result');
      Get.offNamed(AppRoutes.result, arguments: record);
    } on NoFacesDetectedException {
      _log.info('No faces found — showing snackbar');
      Get.back();
      Get.snackbar(
        'No Faces Found',
        'Could not detect any faces in this image. Try a different photo.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } catch (e, stack) {
      _log.error('Processing failed', e, stack);
      Get.back();
      Get.snackbar(
        'Processing Failed',
        'Something went wrong. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }
}
