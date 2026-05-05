import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

part 'usage_log.g.dart';

@HiveType(typeId: AppConstants.usageLogTypeId)
class UsageLog extends HiveObject {

  @HiveField(0)
  late String packageName;

  @HiveField(1)
  late String appName;

  @HiveField(2)
  late String date; // 'yyyy-MM-dd' — key for daily lookup

  @HiveField(3)
  late int totalMinutes;

  @HiveField(4)
  late int sessionCount; // how many times app was opened

  UsageLog({
    required this.packageName,
    required this.appName,
    required this.date,
    required this.totalMinutes,
    required this.sessionCount,
  });
}