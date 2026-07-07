import 'package:hive/hive.dart';
import '../../core/constants/hivebox_names.dart';
import '../models/usage_log.dart';
import '../models/streak.dart';

class UsageStreakRepo {

  // ── Box getters ─────────────────────────────────
  Box<UsageLog> get _usageBox =>
  Hive.box<UsageLog>(HiveBoxNames.usageLogs);

  Box<Streak> get _streakBox =>
  Hive.box<Streak>(HiveBoxNames.streaks);

  // ── Usage logs ──────────────────────────────────

  List<UsageLog> getByDate(String date) {
  return _usageBox.values
      .where((log) => log.date == date)
      .toList();
  }

  List<UsageLog> getLastSevenDays() {
    final today = DateTime.now();
    final sevenDaysAgo = today.subtract(const Duration(days: 7));

    return _usageBox.values.where((log) {
      final logDate = DateTime.parse(log.date);
      return logDate.isAfter(sevenDaysAgo);
    }).toList();
  }

  // returns logs grouped by date for chart rendering
  // { '2026-05-01': [UsageLog, UsageLog], '2026-05-02': [...] }
  Map<String, List<UsageLog>> getLastSevenDaysGrouped() {
    final logs = getLastSevenDays();
    final Map<String, List<UsageLog>> grouped = {};

    for (final log in logs) {
      grouped.putIfAbsent(log.date, () => []).add(log);
  }

    return grouped;
  }

  Future<void> saveLog(UsageLog log) async {
  // key is packageName+date so each app
  // gets one entry per day, not duplicates
    final key = '${log.packageName}_${log.date}';
    await _usageBox.put(key, log);
  }

  Future<void> updateLog(
    String packageName,
    String date,
    int additionalMinutes,
  ) async {
    final key = '${packageName}_$date';
    final existing = _usageBox.get(key);

  if (existing != null) {
  // update existing entry
    existing.totalMinutes += additionalMinutes;
    existing.sessionCount += 1;
    await existing.save();
  } else {
  // no entry yet for today, create one
    await _usageBox.put(key, UsageLog(
    packageName: packageName,
    appName: '',   // foreground service will fill this
    date: date,
    totalMinutes: additionalMinutes,
    sessionCount: 1,
      ));
    }
  }

  // ── Streaks ───────────────────────────────────────────────────────────────────────────────────────────────────────────


  // ── Helpers ─────────────────────────────────────

  String _dateStr(DateTime date) {
    return '${date.year}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
  }
}