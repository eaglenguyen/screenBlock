// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_limit_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimeLimitConfigAdapter extends TypeAdapter<TimeLimitConfig> {
  @override
  final int typeId = 6;

  @override
  TimeLimitConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimeLimitConfig(
      id: fields[0] as String,
      name: fields[1] as String,
      packageNames: (fields[2] as List).cast<String>(),
      limitMinutes: fields[3] as int,
      days: (fields[4] as List).cast<int>(),
      isActive: fields[5] as bool,
      createdAt: fields[6] as DateTime?,
      updatedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TimeLimitConfig obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.packageNames)
      ..writeByte(3)
      ..write(obj.limitMinutes)
      ..writeByte(4)
      ..write(obj.days)
      ..writeByte(5)
      ..write(obj.isActive)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeLimitConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
