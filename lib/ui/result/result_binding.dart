import 'package:get/get.dart';

import 'document_collector_controller.dart';

class ResultBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DocumentCollectorController());
  }
}
