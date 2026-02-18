// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'processing_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProcessingRecordAdapter extends TypeAdapter<ProcessingRecord> {
  @override
  final int typeId = 1;

  @override
  ProcessingRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProcessingRecord(
      id: fields[0] as String,
      type: fields[1] as ProcessingType,
      createdAt: fields[2] as DateTime,
      originalPath: fields[3] as String,
      resultPath: fields[4] as String,
      metadata: (fields[5] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, ProcessingRecord obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.originalPath)
      ..writeByte(4)
      ..write(obj.resultPath)
      ..writeByte(5)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProcessingRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProcessingTypeAdapter extends TypeAdapter<ProcessingType> {
  @override
  final int typeId = 0;

  @override
  ProcessingType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ProcessingType.face;
      case 1:
        return ProcessingType.document;
      default:
        return ProcessingType.face;
    }
  }

  @override
  void write(BinaryWriter writer, ProcessingType obj) {
    switch (obj) {
      case ProcessingType.face:
        writer.writeByte(0);
        break;
      case ProcessingType.document:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProcessingTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
