import 'package:get/get.dart';

import '../../manager/history_manager.dart';
import '../../model/processing_record.dart';

class HomeController extends GetxController {
  final _history = Get.find<HistoryManager>();

  RxList<ProcessingRecord> get records => _history.records;

  Future<void> deleteRecord(String id) async {
    await _history.deleteRecord(id);
  }

  Future<void> restoreRecord(ProcessingRecord record) async {
    await _history.addRecord(record);
  }
}
