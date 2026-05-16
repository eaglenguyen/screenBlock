import 'package:flutter/foundation.dart';

// events the service emits back to the UI
// ViewModel listens to this stream
enum AppEventType {
  timerWarning,   // approaching limit (80% used)
  timerExpired,   // limit reached
  appBlocked,     // app blocked for the day
  appOpened,      // tracked app was opened
}

class AppUsageEvent {
  final String packageName;
  final AppEventType type;
  final int usedMinutes;
  final int limitMinutes;

  const AppUsageEvent({
    required this.packageName,
    required this.type,
    required this.usedMinutes,
    required this.limitMinutes,
  });
}

abstract class BlockingService {

  // ── Monitoring ──────────────────────────────────
  Future<void> startMonitoring(String packageName, int limitMinutes);
  Future<void> stopMonitoring(String packageName);
  Future<void> stopAllMonitoring();

  // ── Blocking ────────────────────────────────────
  Future<void> blockApp(String packageName);
  Future<void> unblockApp(String packageName);

  // ── State ───────────────────────────────────────
  Future<bool> isMonitoring(String packageName);
  Future<int> getUsedMinutesToday(String packageName);
  void resetOverlayState(); // 👈 add this
  void setBlockingMode(String mode);


  // ── Permissions ─────────────────────────────────
  Future<bool> hasUsageStatsPermission();
  Future<bool> hasOverlayPermission();
  Future<void> requestUsageStatsPermission();
  Future<void> requestOverlayPermission();

  Future<bool> hasAccessibilityPermission();
  Future<void> requestAccessibilityPermission();

  // ── Event stream ────────────────────────────────
  // viewmodels subscribe to this to know when
  // to show the interrupt overlay
  Stream<AppUsageEvent> get usageEvents;
}