import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/hivebox_names.dart';
import '../repositories/SettingsRepo.dart';

class SettingsRepositoryImpl implements SettingsRepository {

  // ── Box getter ───────────────────────────────────
  Box get _box => Hive.box(HiveBoxNames.settings);

  // ── XP / gamification ───────────────────────────
  @override
  int getTotalXp() {
    return _box.get('totalXp', defaultValue: 0) as int;
  }

  @override
  Future<void> saveTotalXp(int xp) async {
    await _box.put('totalXp', xp);
  }

  // ── Blocking config ──────────────────────────────
  @override
  String getBlockingType() {
    return _box.get('blockingType',
        defaultValue: AppConstants.blockingTypeSpecificApps) as String;
  }

  @override
  List<String> getBlockedApps() {
    return List<String>.from(_box.get('blockedApps', defaultValue: <String>[]));
  }

  @override
  List<String> getAllowedApps() {
    return List<String>.from(_box.get('allowedApps', defaultValue: <String>[]));
  }

  @override
  Future<void> saveBlockingConfig({
    required String blockingType,
    required List<String> blockedApps,
    required List<String> allowedApps,
  }) async {
    await _box.put('blockingType', blockingType);
    await _box.put('blockedApps', blockedApps);
    await _box.put('allowedApps', allowedApps);
  }

  // ── Screen time / block goals ────────────────────
  @override
  double getDailyScreenTimeGoal() {
    return _box.get('dailyScreenTimeGoal', defaultValue: 3.5) as double;
  }

  @override
  Future<void> saveDailyScreenTimeGoal(double hours) async {
    await _box.put('dailyScreenTimeGoal', hours);
  }

  @override
  double getDailyBlockGoal() {
    return _box.get(HiveBoxNames.blockingGoalHours, defaultValue: 1.0) as double; // 👈 was 'dailyBlockGoal'
  }

  @override
  Future<void> saveDailyBlockGoal(double hours) async {
    await _box.put(HiveBoxNames.blockingGoalHours, hours); // 👈 was 'dailyBlockGoal'
  }
  // ── Review prompt tracking ───────────────────────
  @override
  DateTime? getInstallDate() {
    final ms = _box.get('installDate') as int?;
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  @override
  bool hasRequestedReview(String key) {
    return _box.get(key, defaultValue: false) as bool;
  }

  @override
  Future<void> markReviewRequested(String key) async {
    await _box.put(key, true);
  }
}