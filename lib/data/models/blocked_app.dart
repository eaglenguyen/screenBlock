import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

part 'blocked_app.g.dart';

@HiveType(typeId: AppConstants.blockedAppTypeId)
class BlockedApp extends HiveObject {

  @HiveField(0)
  late String packageName;

  @HiveField(1)
  late DateTime blockedAt;

  @HiveField(2)
  late DateTime blockedUntil; // midnight reset

  BlockedApp({
    required this.packageName,
    required this.blockedAt,
    required this.blockedUntil,
  });

  bool get isStillBlocked => DateTime.now().isBefore(blockedUntil);
}