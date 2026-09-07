// lib/data/models/quick_block.dart
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

part 'quick_block.g.dart';

@HiveType(typeId: AppConstants.quickBlockTypeId) // 👈 allocate a new typeId in app_constants.dart
class QuickBlock extends HiveObject {
  @HiveField(0)
  String packageName;

  @HiveField(1)
  int? durationMinutes; // 👈 null = indefinite; future-proofed for a fixed duration later

  @HiveField(2)
  DateTime startedAt;

  QuickBlock({
    required this.packageName,
    this.durationMinutes,
    required this.startedAt,
  });

  bool get isExpired {
    if (durationMinutes == null) return false; // indefinite never expires on its own
    return DateTime.now().isAfter(startedAt.add(Duration(minutes: durationMinutes!)));
  }
}