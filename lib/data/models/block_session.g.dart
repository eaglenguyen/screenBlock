// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'block_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BlockSessionAdapter extends TypeAdapter<BlockSession> {
  @override
  final int typeId = 5;

  @override
  BlockSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BlockSession(
      startTime: fields[0] as DateTime,
      endTime: fields[1] as DateTime?,
      blockingType: fields[2] as String,
      selectedMinutes: fields[3] as int,
      completed: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, BlockSession obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.startTime)
      ..writeByte(1)
      ..write(obj.endTime)
      ..writeByte(2)
      ..write(obj.blockingType)
      ..writeByte(3)
      ..write(obj.selectedMinutes)
      ..writeByte(4)
      ..write(obj.completed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
