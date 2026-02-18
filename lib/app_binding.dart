import 'package:get/get.dart';

import 'manager/history_manager.dart';
import 'manager/image_processing_manager.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(HistoryManager(), permanent: true);
    Get.put(ImageProcessingManager(), permanent: true);
  }
}
