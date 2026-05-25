import 'package:hive/hive.dart';

part 'block_session.g.dart';

@HiveType(typeId: 5)
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
    return end.difference(startTime);
  }

  bool get isToday {
    final now = DateTime.now();
    return startTime.year == now.year &&
        startTime.month == now.month &&
        startTime.day == now.day;
  }
}