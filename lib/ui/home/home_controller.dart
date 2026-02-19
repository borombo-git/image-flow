import 'package:get/get.dart';

import '../../manager/history_manager.dart';
import '../../model/processing_record.dart';

class HomeController extends GetxController {
  static const _exitAnimDuration = Duration(milliseconds: 300);

  final _history = Get.find<HistoryManager>();
  final deletingId = Rxn<String>();

  RxList<ProcessingRecord> get records => _history.records;

  /// Animates the card out, then removes the record.
  Future<void> deleteRecord(String id) async {
    deletingId.value = id;
    await Future.delayed(_exitAnimDuration);
    await _history.deleteRecord(id);
    deletingId.value = null;
  }

  Future<void> restoreRecord(ProcessingRecord record) async {
    await _history.addRecord(record);
  }
}
