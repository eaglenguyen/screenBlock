import 'package:hive/hive.dart';

import '../../core/constants/app_constants.dart';

part 'time_limit_config.g.dart';

@HiveType(typeId: AppConstants.timeLimitConfigTypeId) // new typeId, pick next unused number
class TimeLimitConfig extends HiveObject {

  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name; // user-facing label, e.g. "Social Media Cap" — same pattern as Schedule.name

  @HiveField(2)
  late List<String> packageNames; // multiple apps sharing this same limit

  @HiveField(3)
  late int limitMinutes; // 1 to 240 (4h), shared across all apps in this config

  @HiveField(4)
  late List<int> days; // 0=Mon ... 6=Sun, matches Schedule's day convention

  @HiveField(5)
  late bool isActive;

  @HiveField(6)
  late DateTime createdAt;

  TimeLimitConfig({
    required this.id,
    required this.name,
    required this.packageNames,
    required this.limitMinutes,
    required this.days,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  TimeLimitConfig copyWith({
    String? id,
    String? name,
    List<String>? packageNames,
    int? limitMinutes,
    List<int>? days,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return TimeLimitConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      packageNames: packageNames ?? this.packageNames,
      limitMinutes: limitMinutes ?? this.limitMinutes,
      days: days ?? this.days,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}