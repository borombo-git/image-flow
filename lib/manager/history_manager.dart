import 'dart:io';

import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../common/utils/logger.dart';
import '../common/utils/path_utils.dart';
import '../model/processing_record.dart';

const _log = AppLogger('📂', 'HISTORY');

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
    _log.info('Box opened – ${records.length} records loaded');
  }

  void _loadRecords() {
    final sorted = _box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    records.assignAll(sorted);
  }

  Future<void> addRecord(ProcessingRecord record) async {
    await _box.put(record.id, record);
    records.insert(0, record);
    _log.info('Record added: ${record.id} (${record.type.name})');
  }

  Future<void> deleteRecord(String id) async {
    final record = getRecord(id);
    if (record != null) {
      await _deleteFiles(record);
    }
    await _box.delete(id);
    records.removeWhere((r) => r.id == id);
    _log.info('Record deleted: $id');
  }

  Future<void> _deleteFiles(ProcessingRecord record) async {
    final metadata = record.metadata;

    // Collect all file paths to delete, using a Set to deduplicate
    // (record.resultPath / originalPath overlap with first page paths)
    final pathSet = <String>{
      resolveDocPath(record.originalPath),
      resolveDocPath(record.resultPath),
      if (metadata?['pdfPath'] != null)
        resolveDocPath(metadata!['pdfPath'] as String),
    };

    // Multi-page records store per-page file lists
    final pageResultPaths = metadata?['pageResultPaths'] as List<dynamic>?;
    final pageOriginalPaths = metadata?['pageOriginalPaths'] as List<dynamic>?;
    if (pageResultPaths != null) {
      for (final p in pageResultPaths) {
        pathSet.add(resolveDocPath(p as String));
      }
    }
    if (pageOriginalPaths != null) {
      for (final p in pageOriginalPaths) {
        pathSet.add(resolveDocPath(p as String));
      }
    }

    for (final path in pathSet) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (e) {
        _log.error('Failed to delete file: $path', e);
      }
    }
  }

  ProcessingRecord? getRecord(String id) {
    return records.firstWhereOrNull((r) => r.id == id);
  }
}
