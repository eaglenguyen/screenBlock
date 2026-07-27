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
  bool completed; // true = timer expired, false = gave up

  BlockSession({
    required this.startTime,
    this.endTime,
    required this.blockingType,
    required this.selectedMinutes,
    this.completed = false,
  });

  Duration get duration {
    final end = endTime ?? DateTime.now();
    final elapsed = end.difference(startTime);

    if (completed) {
      // 👇 a completed session's real duration is exactly its configured length —
      // never more, even if endSession() was called late (e.g. app was
      // backgrounded past the timer's actual expiry)
      final configured = Duration(minutes: selectedMinutes);
      return elapsed < configured ? elapsed : configured;
    }

    // gave up early — real elapsed time is meaningful here, keep as-is
    return elapsed;
  }

  bool get isToday {
    final now = DateTime.now();
    return startTime.year == now.year &&
        startTime.month == now.month &&
        startTime.day == now.day;
  }
}