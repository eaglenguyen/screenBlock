// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timer_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimerConfigAdapter extends TypeAdapter<TimerConfig> {
  @override
  final int typeId = 0;

  @override
  TimerConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimerConfig(
      packageName: fields[0] as String,
      appName: fields[1] as String,
      limitMinutes: fields[2] as int,
      isActive: fields[3] as bool,
      createdAt: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TimerConfig obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.packageName)
      ..writeByte(1)
      ..write(obj.appName)
      ..writeByte(2)
      ..write(obj.limitMinutes)
      ..writeByte(3)
      ..write(obj.isActive)
      ..writeByte(4)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimerConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
