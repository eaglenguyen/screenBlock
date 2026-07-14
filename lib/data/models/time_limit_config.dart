import 'package:hive/hive.dart';

import '../../core/constants/app_constants.dart';
part 'time_limit_config.g.dart'; // 👈 confirm this line exists, exact filename match


@HiveType(typeId: AppConstants.timeLimitConfigTypeId)
class TimeLimitConfig extends HiveObject {

  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late List<String> packageNames;

  @HiveField(3)
  late int limitMinutes;

  @HiveField(4)
  late List<int> days;

  @HiveField(5)
  late bool isActive;

  @HiveField(6)
  late DateTime createdAt;

  @HiveField(7)
  late DateTime updatedAt; // 👈 new

  TimeLimitConfig({
    required this.id,
    required this.name,
    required this.packageNames,
    required this.limitMinutes,
    required this.days,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  TimeLimitConfig copyWith({
    String? id,
    String? name,
    List<String>? packageNames,
    int? limitMinutes,
    List<int>? days,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimeLimitConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      packageNames: packageNames ?? this.packageNames,
      limitMinutes: limitMinutes ?? this.limitMinutes,
      days: days ?? this.days,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(), // 👈 defaults to "now" unless explicitly overridden
    );
  }
}