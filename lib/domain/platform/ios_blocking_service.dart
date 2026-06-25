import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'blocking_service.dart';

class IOSBlockingService implements BlockingService {

  static const _channel = MethodChannel(
    'com.eagle.pausenow/ios_blocking',
  );

  final _eventController =
  StreamController<AppUsageEvent>.broadcast();

  // ── Authorization ────────────────────────────────
  Future<bool> requestAuthorization() async {
    try {
      final result = await _channel
          .invokeMethod<bool>('requestAuthorization');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isAuthorized() async {
    try {
      final result = await _channel
          .invokeMethod<bool>('isAuthorized');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<int?> showAppPicker({
    String blockingMode = 'specific_apps',
  }) async {
    await _channel.invokeMethod<void>('saveBlockingMode', {
      'mode': blockingMode,
    });
    final count = await _channel.invokeMethod<int>('showAppPicker');
    debugPrint('🔵 iOS picker returned: $count apps saved');
    return count;
  }

  // ── Monitoring ───────────────────────────────────
  @override
  Future<void> startMonitoring(
      String packageName,
      int limitMinutes, [
      String sessionType = 'manual',
      String blockingMode = 'specific_apps',
      ]) async {
    await _channel.invokeMethod('startBlocking', {
      'packageNames': [packageName],
      'blockingMode': blockingMode,
      'limitMinutes': limitMinutes,
      'sessionType': sessionType,
    });
  }

  @override
  Future<void> stopMonitoring(String packageName) async {
    await _channel.invokeMethod('stopBlocking');
  }

  @override
  Future<void> stopAllMonitoring() async {
    await _channel.invokeMethod('stopBlocking');
  }

  @override
  Future<bool> isMonitoring(String packageName) async {
    return false;
  }

  // ── Blocking ─────────────────────────────────────
  @override
  Future<void> blockApp(String packageName) async {
    // iOS handles blocking at OS level
  }

  @override
  Future<void> unblockApp(String packageName) async {
    await _channel.invokeMethod('stopBlocking');
  }

  @override
  void resetOverlayState() {}

  @override
  void setBlockingMode(String mode) {}

  Future<void> persistSessionType(String type) async {
    try {
      await _channel.invokeMethod('persistSessionType', {'type': type});
    } catch (e) {
      debugPrint('❌ persistSessionType error: $e');
    }
  }

  // ── Permissions ──────────────────────────────────
  @override
  Future<bool> hasAccessibilityPermission() async {
    return isAuthorized();
  }

  @override
  Future<void> requestAccessibilityPermission() async {
    await requestAuthorization();
  }

  @override
  Future<bool> hasUsageStatsPermission() async {
    return isAuthorized();
  }

  @override
  Future<bool> hasOverlayPermission() async {
    return true;
  }

  @override
  Future<void> requestUsageStatsPermission() async {
    await requestAuthorization();
  }

  @override
  Future<void> requestOverlayPermission() async {
    // not needed on iOS
  }

  @override
  Future<int> getUsedMinutesToday(String packageName) async {
    return 0;
  }

  Future<void> savePauseEndTime(int endTimeMs) async {
    try {
      await _channel.invokeMethod('savePauseEndTime', {'endTimeMs': endTimeMs});
    } catch (e) {
      debugPrint('❌ savePauseEndTime iOS error: $e');
    }
  }
// IOS logic

  Future<void> pauseBlocking(int minutes) async {
    try {
      await _channel.invokeMethod('pauseBlocking', {'minutes': minutes});
      debugPrint('⏸ iOS pauseBlocking: $minutes mins');
    } catch (e) {
      debugPrint('❌ pauseBlocking error: $e');
    }
  }

  Future<void> resumeBlocking() async {
    try {
      await _channel.invokeMethod('resumeBlocking');
      debugPrint('▶️ iOS resumeBlocking called');
    } catch (e) {
      debugPrint('❌ resumeBlocking error: $e');
    }
  }

  Future<void> stopBlockingCompletely() async {
    try {
      await _channel.invokeMethod('stopBlockingCompletely');
      debugPrint('🛑 iOS stopBlockingCompletely called');
    } catch (e) {
      debugPrint('❌ stopBlockingCompletely error: $e');
    }
  }

  @override
  Stream<AppUsageEvent> get usageEvents =>
      _eventController.stream;
}