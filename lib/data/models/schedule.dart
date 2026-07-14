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

  @HiveField(10)
  late DateTime updatedAt; // 👈 new — next available field index

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
    DateTime? updatedAt,

  })  : blockedApps = blockedApps ?? [],
        allowedApps = allowedApps ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();




  // display helpers
  String get timeRange {
    if (startTime == '00:00' && endTime == '23:59') return 'All Day';
    return '${_formatTime(startTime)} - ${_formatTime(endTime)}';
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : hour > 12 ? hour - 12 : hour;
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  String get daysDisplay {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    if (days.length == 7) return 'Every day';
    if (days.length == 5 &&
        !days.contains(5) &&
        !days.contains(6)) {
      return 'Weekdays';
    }
    if (days.length == 2 &&
        days.contains(5) &&
        days.contains(6)) {
      return 'Weekends';
    }
    return days.map((d) => labels[d]).join(' ');
  }

  Schedule copyWith({
    String? id,
    String? name,
    String? startTime,
    String? endTime,
    List<int>? days,
    String? blockingType,
    List<String>? blockedApps,
    List<String>? allowedApps,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,

  }) {
    return Schedule(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      days: days ?? this.days,
      blockingType: blockingType ?? this.blockingType,
      blockedApps: blockedApps ?? this.blockedApps,
      allowedApps: allowedApps ?? this.allowedApps,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(), // 👈 defaults to "now" on every copyWith call

    );
  }
}