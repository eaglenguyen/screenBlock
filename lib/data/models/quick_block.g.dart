// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quick_block.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuickBlockAdapter extends TypeAdapter<QuickBlock> {
  @override
  final int typeId = 7;

  @override
  QuickBlock read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuickBlock(
      packageName: fields[0] as String,
      durationMinutes: fields[1] as int?,
      startedAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, QuickBlock obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.packageName)
      ..writeByte(1)
      ..write(obj.durationMinutes)
      ..writeByte(2)
      ..write(obj.startedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuickBlockAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
