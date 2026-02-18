import 'package:get/get.dart';

import 'manager/history_manager.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(HistoryManager(), permanent: true);
  }
}
