import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../model/processing_record.dart';

/// Manages processing history persistence with Hive.
class HistoryManager extends GetxController {
  static const _boxName = 'processing_history';

  late Box<ProcessingRecord> _box;
  final records = <ProcessingRecord>[].obs;

  @override
  void onInit() {
    super.onInit();
    _openBox();
  }

  Future<void> _openBox() async {
    _box = await Hive.openBox<ProcessingRecord>(_boxName);
    _loadRecords();
    debugPrint('📂 [HISTORY] Box opened – ${records.length} records loaded');
  }

  void _loadRecords() {
    final sorted = _box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    records.assignAll(sorted);
  }

  Future<void> addRecord(ProcessingRecord record) async {
    await _box.put(record.id, record);
    records.insert(0, record);
    debugPrint('📂 [HISTORY] Record added: ${record.id} (${record.type.name})');
  }

  Future<void> deleteRecord(String id) async {
    await _box.delete(id);
    records.removeWhere((r) => r.id == id);
    debugPrint('📂 [HISTORY] Record deleted: $id');
  }

  ProcessingRecord? getRecord(String id) {
    return records.firstWhereOrNull((r) => r.id == id);
  }
}
