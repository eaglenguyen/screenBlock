import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

part 'block_session.g.dart';

@HiveType(typeId: AppConstants.blockSessionTypeId)
class BlockSession extends HiveObject {
  @HiveField(0)
  DateTime startTime;

  @HiveField(1)
  DateTime? endTime;

  @HiveField(2)
  String blockingType;

  @HiveField(3)
  int selectedMinutes;

  @HiveField(4)
  bool completed;

  @HiveField(5)
  int? activeSeconds; // 👈 new — nullable so old records without it don't break; null = fall back to old calculation

  BlockSession({
    required this.startTime,
    this.endTime,
    required this.blockingType,
    required this.selectedMinutes,
    this.completed = false,
    this.activeSeconds,
  });

  Duration get duration {
    // 👇 new — if we have a real tracked active-seconds value, trust it directly
    if (activeSeconds != null) {
      return Duration(seconds: activeSeconds!);
    }

    // 👇 fallback — old behavior, for any session recorded before this change
    final end = endTime ?? DateTime.now();
    final elapsed = end.difference(startTime);
    if (completed) {
      final configured = Duration(minutes: selectedMinutes);
      return elapsed < configured ? elapsed : configured;
    }
    return elapsed;
  }

  bool get isToday {
    final now = DateTime.now();
    return startTime.year == now.year &&
        startTime.month == now.month &&
        startTime.day == now.day;
  }
}