import 'package:get/get.dart';

import '../../common/utils/logger.dart';

const _log = AppLogger('⚙️', 'PROCESSING');

class ProcessingController extends GetxController {
  final imagePath = ''.obs;
  final currentStep = 'Analyzing Image...'.obs;
  final stepDescription = 'Detecting content type'.obs;
  final progress = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    imagePath.value = Get.arguments as String? ?? '';
    _log.info('Started with image: ${imagePath.value}');
  }
}
