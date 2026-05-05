import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

part 'timer_config.g.dart';

@HiveType(typeId: AppConstants.timerConfigTypeId) // aka TypeConverter , annotation generates adapter
class TimerConfig extends HiveObject { // HO -> gives save, delete, key

  @HiveField(0)
  late String packageName;

  @HiveField(1)
  late String appName;

  @HiveField(2)
  late int limitMinutes;

  @HiveField(3)
  late bool isActive;

  @HiveField(4)
  late DateTime createdAt;

  TimerConfig({
    required this.packageName,
    required this.appName,
    required this.limitMinutes,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}