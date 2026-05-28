// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UsageLogAdapter extends TypeAdapter<UsageLog> {
  @override
  final int typeId = 2;

  @override
  UsageLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UsageLog(
      packageName: fields[0] as String,
      appName: fields[1] as String,
      date: fields[2] as String,
      totalMinutes: fields[3] as int,
      sessionCount: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, UsageLog obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.packageName)
      ..writeByte(1)
      ..write(obj.appName)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.totalMinutes)
      ..writeByte(4)
      ..write(obj.sessionCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsageLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
