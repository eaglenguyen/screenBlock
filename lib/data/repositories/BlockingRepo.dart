
import '../models/blocked_app.dart';
import '../models/timer_config.dart';

abstract class BlockingRepository {

  // ── Timer config ────────────────────────────────
  List<TimerConfig> getAllTimers();
  TimerConfig? getTimer(String packageName);
  Future<void> saveTimer(TimerConfig config);
  Future<void> deleteTimer(String packageName);
  bool hasReachedFreeLimit();

  // ── Blocked apps ────────────────────────────────
  List<BlockedApp> getAllBlocked();
  bool isBlocked(String packageName);
  Future<void> blockApp(String packageName);
  Future<void> unblockApp(String packageName);
  Future<void> clearExpiredBlocks();
}