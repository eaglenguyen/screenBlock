import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

part 'schedule.g.dart';

@HiveType(typeId: 4)
class Schedule extends HiveObject {

  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String startTime; // '12:00'

  @HiveField(3)
  late String endTime;   // '17:00'

  @HiveField(4)
  late List<int> days;   // 0=Mon, 1=Tue ... 6=Sun

  @HiveField(5)
  late String blockingType; // 'all_apps' or 'specific_apps'

  @HiveField(6)
  late List<String> blockedApps; // package names

  @HiveField(7)
  late List<String> allowedApps; // package names

  @HiveField(8)
  late bool isActive;

  @HiveField(9)
  late DateTime createdAt;

  Schedule({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.days,
    required this.blockingType,
    List<String>? blockedApps,
    List<String>? allowedApps,
    this.isActive = true,
    DateTime? createdAt,
  })  : blockedApps = blockedApps ?? [],
        allowedApps = allowedApps ?? [],
        createdAt = createdAt ?? DateTime.now();

  // display helpers
  String get timeRange => '$startTime - $endTime';

  String get daysDisplay {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    if (days.length == 7) return 'Every day';
    if (days.length == 5 &&
        !days.contains(5) &&
        !days.contains(6)) return 'Weekdays';
    if (days.length == 2 &&
        days.contains(5) &&
        days.contains(6)) return 'Weekends';
    return days.map((d) => labels[d]).join(' ');
  }
}