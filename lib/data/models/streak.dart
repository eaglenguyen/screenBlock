import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

part 'streak.g.dart';

@HiveType(typeId: AppConstants.streakTypeId)
class Streak extends HiveObject {

  @HiveField(0)
  late int currentStreak;

  @HiveField(1)
  late int longestStreak;

  @HiveField(2)
  late DateTime lastCheckedDate;

  @HiveField(3)
  late bool completedToday;

  Streak({
    this.currentStreak = 0,
    this.longestStreak = 0,
    DateTime? lastCheckedDate,
    this.completedToday = false,
  }) : lastCheckedDate = lastCheckedDate ?? DateTime.now();
}