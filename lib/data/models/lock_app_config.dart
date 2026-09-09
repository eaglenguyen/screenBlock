import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

part 'lock_app_config.g.dart';

@HiveType(typeId: AppConstants.lockAppConfigTypeId) // 👈 allocate next unused number (8)
class LockAppConfig extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String packageName; // 👈 single app only, per your spec

  @HiveField(3)
  int maxUnlocks;

  @HiveField(4)
  int unlocksUsedToday;

  @HiveField(5)
  DateTime lastResetDate;

  @HiveField(6)
  bool isActive;

  @HiveField(7)
  DateTime updatedAt;

  @HiveField(8)
  String appName; // 👈 new — resolved display name, e.g. "Discord"

  @HiveField(9)
  DateTime? pauseEndsAt;

  @HiveField(10)
  String? iconUrl; // 👈 new — App Store artwork URL, iOS only


  LockAppConfig({
    required this.id,
    required this.name,
    required this.packageName,
    required this.maxUnlocks,
    this.unlocksUsedToday = 0,
    required this.lastResetDate,
    this.isActive = true,
    required this.updatedAt,
    required this.appName,
    this.pauseEndsAt, // 👈 new
    this.iconUrl, //

  });

  int get remaining => (maxUnlocks - unlocksUsedToday).clamp(0, maxUnlocks);
  bool get isExhausted => remaining <= 0;
  bool get isPausing => pauseEndsAt != null && DateTime.now().isBefore(pauseEndsAt!);
}