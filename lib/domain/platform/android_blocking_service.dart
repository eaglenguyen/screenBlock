import 'dart:async';
import 'package:app_usage/app_usage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart' hide NotificationVisibility;
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'blocking_service.dart';
import 'foreground_task_handler.dart';


class AndroidBlockingService implements BlockingService {

  final _eventController =
  StreamController<AppUsageEvent>.broadcast();

  // in-memory monitored apps
  // packageName → limitMinutes
  final Map<String, int> _monitoredApps = {};

  // ── Foreground task setup ────────────────────────
  static void _initForegroundTask() {
    debugPrint('🟡 initializing foreground task...');

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'focus_blocker_channel',
        channelName: 'Focus Blocker',
        channelDescription:
        'Monitoring app usage in the background',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
    debugPrint('🟡 foreground task initialized');

  }

  // ── Monitoring ───────────────────────────────────
  @override
  Future<void> startMonitoring(
      String packageName,
      int limitMinutes,
      ) async {
    debugPrint('🟡 startMonitoring: $packageName');
    _monitoredApps[packageName] = limitMinutes;
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);


    _initForegroundTask();
    await _startForegroundService();
  }

  void _onTaskData(Object data) {
    debugPrint('🟢 task data received: $data');
    if (data is String) {
      _onForegroundAppDetected(data);
    }
  }

  @override
  Future<void> stopMonitoring(String packageName) async {
    _monitoredApps.remove(packageName);
    if (_monitoredApps.isEmpty) {
      await FlutterForegroundTask.stopService();
    }
  }

  @override
  Future<void> stopAllMonitoring() async {
    _monitoredApps.clear();
    await FlutterForegroundTask.stopService();
  }

  Future<void> _startForegroundService() async {
    debugPrint('🟡 checking if service is running...');
    final isRunning = await FlutterForegroundTask.isRunningService;
    debugPrint('🟡 isRunning: $isRunning');
    // add this listener for data coming from the task handler
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);

    if (isRunning) {
      debugPrint('🟡 restarting service...');
      await FlutterForegroundTask.restartService();
    } else {
      debugPrint('🟡 starting service...');
      try {
        await FlutterForegroundTask.startService(
          notificationTitle: 'Focus is active',
          notificationText: 'Monitoring your app usage',
          callback: startForegroundCallback,
        );
        debugPrint('🟡 service start called');
      } catch (e) {
        debugPrint('❌ service start failed: $e');
      }
    }

    // send monitored apps to the task isolate
    // so it knows which apps to watch for
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('🟡 sending monitored apps to task: $_monitoredApps');
    FlutterForegroundTask.sendDataToTask(_monitoredApps);
  }

  void _onForegroundAppDetected(String packageName) {
    debugPrint('🟢 foreground app detected in main: $packageName');

    if (!_monitoredApps.containsKey(packageName)) return;

    final limitMinutes = _monitoredApps[packageName]!;

    // get today's usage then decide whether to block
    getUsedMinutesToday(packageName).then((usedMinutes) {
      debugPrint('🟡 $packageName used: ${usedMinutes}m limit: ${limitMinutes}m');

      if (usedMinutes >= limitMinutes) {
        // limit reached — block
        _eventController.add(AppUsageEvent(
          packageName: packageName,
          type: AppEventType.timerExpired,
          usedMinutes: usedMinutes,
          limitMinutes: limitMinutes,
        ));
        _showOverlay(packageName);
      } else if (usedMinutes >= (limitMinutes * 0.8).floor()) {
        // 80% of limit — warning
        _eventController.add(AppUsageEvent(
          packageName: packageName,
          type: AppEventType.timerWarning,
          usedMinutes: usedMinutes,
          limitMinutes: limitMinutes,
        ));
      }
    });
  }


  // ── Blocking ─────────────────────────────────────
  @override
  Future<void> blockApp(String packageName) async {
    _eventController.add(AppUsageEvent(
      packageName: packageName,
      type: AppEventType.appBlocked,
      usedMinutes: _monitoredApps[packageName] ?? 0,
      limitMinutes: _monitoredApps[packageName] ?? 0,
    ));
    await _showOverlay(packageName);
  }

  @override
  Future<void> unblockApp(String packageName) async {
    await FlutterOverlayWindow.closeOverlay();
  }

  // ── Overlay ──────────────────────────────────────
  Future<void> _showOverlay(String packageName) async {
    if (!await FlutterOverlayWindow.isPermissionGranted()) {
      await FlutterOverlayWindow.requestPermission();
      return;
    }

    await FlutterOverlayWindow.showOverlay(
      enableDrag: false,
      overlayTitle: 'App Blocked',
      overlayContent: packageName,
      flag: OverlayFlag.defaultFlag,
      visibility: NotificationVisibility.visibilityPublic,
      positionGravity: PositionGravity.auto,
      width: WindowSize.fullCover,
      height: WindowSize.fullCover,
    );
  }

  // ── State ────────────────────────────────────────
  @override
  Future<bool> isMonitoring(String packageName) async {
    return _monitoredApps.containsKey(packageName);
  }

  @override
  Future<int> getUsedMinutesToday(
      String packageName,
      ) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(
        now.year, now.month, now.day,
      );

      final usage = await AppUsage().getAppUsage(
        startOfDay,
        now,
      );

      final matches = usage.where(
            (u) => u.packageName == packageName,
      );

      if (matches.isEmpty) return 0;

      return matches.first.usage.inMinutes;
      // 👆 usage is already a Duration so just use .inMinutes
    } catch (e) {
      return 0;
    }
  }

  // ── Permissions ──────────────────────────────────
  @override
  Future<bool> hasUsageStatsPermission() async {
    try {
      final now = DateTime.now();
      final usage = await AppUsage().getAppUsage(
        now.subtract(const Duration(hours: 1)),
        now,
      );
      return usage.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> hasOverlayPermission() async {
    return await FlutterOverlayWindow.isPermissionGranted();
  }

  @override
  Future<void> requestUsageStatsPermission() async {
    await FlutterForegroundTask.openSystemAlertWindowSettings();
  }

  @override
  Future<void> requestOverlayPermission() async {
    await FlutterOverlayWindow.requestPermission();
  }

  // ── Stream ───────────────────────────────────────
  @override
  Stream<AppUsageEvent> get usageEvents =>
      _eventController.stream;
}

