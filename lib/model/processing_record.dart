import 'package:hive/hive.dart';

part 'processing_record.g.dart';

@HiveType(typeId: 0)
enum ProcessingType {
  @HiveField(0)
  face,

  @HiveField(1)
  document,
}

@HiveType(typeId: 1)
class ProcessingRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final ProcessingType type;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final String originalPath;

  @HiveField(4)
  final String resultPath;

  @HiveField(5)
  final Map<String, dynamic>? metadata;

  ProcessingRecord({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.originalPath,
    required this.resultPath,
    this.metadata,
  });
}
