// Hive Implementation

import 'package:hive/hive.dart';
import 'package:screenblock/data/repositories/BlockingRepo.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/hivebox_names.dart';
import '../models/timer_config.dart';
import '../models/blocked_app.dart';

class BlockingRepositoryImpl implements BlockingRepository {

  // ── Box getters ─────────────────────────────────
  Box<TimerConfig> get _timerBox =>
      Hive.box<TimerConfig>(HiveBoxNames.timerConfigs);

  Box<BlockedApp> get _blockedBox =>
      Hive.box<BlockedApp>(HiveBoxNames.blockedApps);

  // ── Timer config ────────────────────────────────────────────────────────────────────────────────────────────────

  @override
  List<TimerConfig> getAllTimers() {
    return _timerBox.values.toList();
  }

  @override
  TimerConfig? getTimer(String packageName) {
    try {
      return _timerBox.values.firstWhere(
            (c) => c.packageName == packageName,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveTimer(TimerConfig config) async {
    // using packageName as key so saving the same
    // app twice updates it rather than duplicating
    await _timerBox.put(config.packageName, config);
  }

  @override
  Future<void> deleteTimer(String packageName) async {
    await _timerBox.delete(packageName);
  }

  @override
  bool hasReachedFreeLimit() {
    return _timerBox.length >= AppConstants.freeTrackedAppsLimit;
  }

  // ── Blocked apps ────────────────────────────────────────────────────────────────────────────────────────────────

  @override
  List<BlockedApp> getAllBlocked() {
    return _blockedBox.values.toList();
  }

  @override
  bool isBlocked(String packageName) {
    try {
      final blocked = _blockedBox.values.firstWhere(
            (b) => b.packageName == packageName,
      );
      // check if block is still valid
      // if midnight has passed it's expired
      return blocked.isStillBlocked;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> blockApp(String packageName) async {
    final now = DateTime.now();

    // block until midnight tonight
    final midnight = DateTime(
      now.year,
      now.month,
      now.day + 1, // next day
      0, 0, 0,     // 00:00:00
    );

    final blocked = BlockedApp(
      packageName: packageName,
      blockedAt: now,
      blockedUntil: midnight,
    );

    // using packageName as key same reason as timerBox
    await _blockedBox.put(packageName, blocked);
  }

  @override
  Future<void> unblockApp(String packageName) async {
    await _blockedBox.delete(packageName);
  }

  @override
  Future<void> clearExpiredBlocks() async {
    // get all keys whose blocks have expired
    final expiredKeys = _blockedBox.values
        .where((b) => !b.isStillBlocked)
        .map((b) => b.packageName)
        .toList();

    await _blockedBox.deleteAll(expiredKeys);
  }
}