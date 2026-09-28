// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lock_app_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LockAppConfigAdapter extends TypeAdapter<LockAppConfig> {
  @override
  final int typeId = 8;

  @override
  LockAppConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LockAppConfig(
      id: fields[0] as String,
      name: fields[1] as String,
      packageName: fields[2] as String,
      maxUnlocks: fields[3] as int,
      unlocksUsedToday: fields[4] as int,
      lastResetDate: fields[5] as DateTime,
      isActive: fields[6] as bool,
      updatedAt: fields[7] as DateTime,
      appName: fields[8] as String,
      pauseEndsAt: fields[9] as DateTime?,
      iconUrl: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LockAppConfig obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.packageName)
      ..writeByte(3)
      ..write(obj.maxUnlocks)
      ..writeByte(4)
      ..write(obj.unlocksUsedToday)
      ..writeByte(5)
      ..write(obj.lastResetDate)
      ..writeByte(6)
      ..write(obj.isActive)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.appName)
      ..writeByte(9)
      ..write(obj.pauseEndsAt)
      ..writeByte(10)
      ..write(obj.iconUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LockAppConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
