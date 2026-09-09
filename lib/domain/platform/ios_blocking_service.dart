import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../blocking_service.dart';

class IOSBlockingService implements BlockingService {

  static const _channel = MethodChannel(
    'com.eagle.pausenow/ios_blocking',
  );
  static void listenForNativeEvents({
    required VoidCallback onPauseEnded,
    required VoidCallback onSessionComplete,
    required VoidCallback onNotificationStartBreak, // 👈 add
    required VoidCallback onNotificationStartWork,  // 👈 add
    required VoidCallback onNotificationExtendBreak, // 👈 add
    required VoidCallback? onShowCheckInFlow, // 👈 new

  }) {
    const channel = MethodChannel('com.eagle.pausenow/ios_blocking');
    channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onPauseEnded':
          onPauseEnded();
          break;
        case 'showCheckInFlow':
          onShowCheckInFlow?.call();
          break;
        case 'onSessionComplete':
          onSessionComplete();
          break;
        case 'onNotificationStartBreak': // 👈 add
          onNotificationStartBreak();
          break;
        case 'onNotificationStartWork': // 👈 add
          onNotificationStartWork();
          break;
        case 'onNotificationExtendBreak': // 👈 add
          onNotificationExtendBreak();
          break;
      }
    });
  }
  static VoidCallback? onShowCheckInFlow; // 👈 new



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

  Future<int?> showSchedulePicker({
    required String scheduleId,
    required String blockingMode,
  }) async {
    await _channel.invokeMethod<void>('saveBlockingMode', {
      'mode': blockingMode,
    });
    final count = await _channel.invokeMethod<int>('showSchedulePicker', {
      'scheduleId': scheduleId,
      'blockingMode': blockingMode,
    });
    debugPrint('🔵 iOS schedule picker returned: $count apps saved');
    return count;
  }

  Future<int?> showTimeLimitAppPicker({required String configId}) async {
    final count = await _channel.invokeMethod<int>('showTimeLimitAppPicker', {
      'configId': configId,
    });
    debugPrint('🔵 iOS time-limit picker returned: $count apps saved');
    return count;
  }

  // ── Monitoring ───────────────────────────────────
  @override
  Future<void> startMonitoring(
      String packageName,
      int limitMinutes, {
        String sessionType = 'manual',
        String blockingMode = 'specific_apps',
        String? scheduleId,
        bool isPomodoro = false,
      }) async {
    await _channel.invokeMethod('startBlocking', {
      'packageNames': [packageName],
      'blockingMode': blockingMode,
      'limitMinutes': limitMinutes,
      'sessionType': sessionType,
      if (scheduleId != null) 'scheduleId': scheduleId, // 👈 fixed
      'isPomodoro': isPomodoro,

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

  Future<void> setSessionComplete() async {
    try {
      await _channel.invokeMethod('setSessionComplete');
      debugPrint('✅ setSessionComplete called');
    } catch (e) {
      debugPrint('❌ setSessionComplete error: $e');
    }
  }

  Future<void> playSystemSound(int soundId) async {
    try {
      await _channel.invokeMethod('playSystemSound', {'soundId': soundId});
    } catch (e) {
      debugPrint('❌ playSystemSound error: $e');
    }
  }

  Future<void> pauseBlocking(int minutes) async {
    try {
      await _channel.invokeMethod('pauseBlocking', {'minutes': minutes});
      debugPrint('⏸ iOS pauseBlocking: $minutes mins');
    } catch (e) {
      debugPrint('❌ pauseBlocking error: $e');
    }
  }

  Future<void> stopSessionMonitoring() async {
    try {
      await _channel.invokeMethod('stopSessionMonitoring');
    } catch (e) {
      debugPrint('❌ stopSessionMonitoring error: $e');
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

  Future<void> syncScheduleMonitoring(List<Map<String, dynamic>> schedules) async {
    try {
      await _channel.invokeMethod('syncScheduleMonitoring', {'schedules': schedules});
    } catch (e) {
      debugPrint('❌ syncScheduleMonitoring error: $e');
    }
  }


  Future<void> updateLiveActivity({
    DateTime? endTime,
    required bool isPaused,
    int pausedRemainingSeconds = 0,
    bool isOnBreak = false,
  }) async {
    try {
      await const MethodChannel('com.eagle.pausenow/ios_blocking').invokeMethod(
        'updateLiveActivity',
        {
          'endTime': (endTime ?? DateTime.now()).millisecondsSinceEpoch / 1000,
          'isPaused': isPaused,
          'pausedRemainingSeconds': pausedRemainingSeconds,
          'isOnBreak' : isOnBreak,
        },
      );
    } catch (e) {
      debugPrint('❌ updateLiveActivity error: $e');
    }
  }

  Future<void> liftShieldOnly() async {
    try {
      await _channel.invokeMethod('liftShieldOnly');
    } catch (e) {
      debugPrint('❌ liftShieldOnly error: $e');
    }
  }

  Future<int?> showQuickBlockPicker({required String cardId, required String appLabel}) async {
    final count = await _channel.invokeMethod<int>('showQuickBlockPicker', {
      'cardId': cardId,
      'appLabel': appLabel,
    });
    return count;
  }

  Future<void> toggleQuickBlock({required String cardId, required bool blocked}) async {
    await _channel.invokeMethod('toggleQuickBlock', {'cardId': cardId, 'blocked': blocked});
  }

  Future<bool> hasQuickBlockSelection(String cardId) async {
    final result = await _channel.invokeMethod<bool>('hasQuickBlockSelection', {'cardId': cardId});
    return result ?? false;
  }
  Future<void> resetQuickBlockSelection(String cardId) async {
    await _channel.invokeMethod('resetQuickBlockSelection', {'cardId': cardId});
  }

  Future<int?> showLockAppPicker({required String configId, String appLabel = ''}) async {
    final count = await _channel.invokeMethod<int>('showLockAppPicker', {
      'configId': configId,
      'appLabel': appLabel,
    });
    return count;
  }

  Future<void> applyLockAppShield(String configId) async {
    try {
      await _channel.invokeMethod('applyLockAppShield', {'configId': configId});
    } catch (e) {
      debugPrint('❌ applyLockAppShield error: $e');
    }
  }

  Future<void> removeLockAppShield(String configId) async {
    try {
      await _channel.invokeMethod('removeLockAppShield', {'configId': configId});
    } catch (e) {
      debugPrint('❌ removeLockAppShield error: $e');
    }
  }

  Future<void> saveLockAppConfigIds(List<String> ids) async {
    try {
      await _channel.invokeMethod('saveLockAppConfigIds', {'ids': ids});
    } catch (e) {
      debugPrint('❌ saveLockAppConfigIds error: $e');
    }
  }

  Future<void> saveLockAppRemaining(String configId, int remaining, int max) async {
    try {
      await _channel.invokeMethod('saveLockAppRemaining', {
        'configId': configId,
        'remaining': remaining,
        'max': max,
      });
    } catch (e) {
      debugPrint('❌ saveLockAppRemaining error: $e');
    }
  }

  Future<void> endLockAppPauseEarly(String configId) async {
    try {
      await _channel.invokeMethod('endLockAppPauseEarly', {'configId': configId});
    } catch (e) {
      debugPrint('❌ endLockAppPauseEarly error: $e');
    }
  }

  Future<void> deleteLockAppConfig(String configId) async {
    try {
      await _channel.invokeMethod('deleteLockAppConfig', {'configId': configId});
    } catch (e) {
      debugPrint('❌ deleteLockAppConfig error: $e');
    }
  }

  @override
  Stream<AppUsageEvent> get usageEvents =>
      _eventController.stream;
}