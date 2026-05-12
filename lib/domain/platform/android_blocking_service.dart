import 'dart:async';

import 'package:app_usage/app_usage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import 'blocking_service.dart';

class AndroidBlockingService implements BlockingService {
  bool _overlayShowing = false;
  // add method channel call to launch BlockActivity
  static const _blockChannel = MethodChannel(
    'com.example.screenblock/block',
  );

  final _eventController =
  StreamController<AppUsageEvent>.broadcast();

  final Map<String, int> _monitoredApps = {};

  // method channel for permission checks
  static const _methodChannel = MethodChannel(
    'com.example.screenblock/accessibility',
  );

  // event channel for foreground app changes
  static const _eventChannel = EventChannel(
    'com.example.screenblock/foreground_app',
  );

  StreamSubscription? _foregroundAppSubscription;

  // ── Monitoring ───────────────────────────────────
  @override
  Future<void> startMonitoring(
      String packageName,
      int limitMinutes,
      ) async {
    debugPrint('🟡 startMonitoring: $packageName');
    _monitoredApps[packageName] = limitMinutes;
    _startListening();
  }

  void _startListening() {
    // cancel existing subscription first
    _foregroundAppSubscription?.cancel();

    _foregroundAppSubscription = _eventChannel
        .receiveBroadcastStream()
        .listen((dynamic packageName) {
      if (packageName is String) {
        debugPrint('🟢 foreground app changed: $packageName');
        _onForegroundAppChanged(packageName);
      }
    }, onError: (error) {
      debugPrint('❌ event channel error: $error');
    });
  }


  void _onForegroundAppChanged(String packageName) {
    if (!_monitoredApps.containsKey(packageName)) return;
    if (_overlayShowing) return;

    final limitMinutes = _monitoredApps[packageName]!;

    getUsedMinutesToday(packageName).then((usedMinutes) {
      debugPrint('🟡 $packageName used: ${usedMinutes}m limit: ${limitMinutes}m');

      if (usedMinutes >= limitMinutes) {
        _overlayShowing = true;
        _eventController.add(AppUsageEvent(
          packageName: packageName,
          type: AppEventType.timerExpired,
          usedMinutes: usedMinutes,
          limitMinutes: limitMinutes,
        ));
        // don't call _showOverlay here
        // let HomeViewModel handle it from main isolate
      } else if (usedMinutes >= (limitMinutes * 0.8).floor()) {
        _eventController.add(AppUsageEvent(
          packageName: packageName,
          type: AppEventType.timerWarning,
          usedMinutes: usedMinutes,
          limitMinutes: limitMinutes,
        ));
      }
    });
  }

  @override
  Future<void> stopMonitoring(String packageName) async {
    _monitoredApps.remove(packageName);
    if (_monitoredApps.isEmpty) {
      _foregroundAppSubscription?.cancel();
      _foregroundAppSubscription = null;
    }
  }

  @override
  Future<void> stopAllMonitoring() async {
    _monitoredApps.clear();
    _foregroundAppSubscription?.cancel();
    _foregroundAppSubscription = null;
  }

  // ── Permissions ──────────────────────────────────
  @override
  Future<bool> hasAccessibilityPermission() async {
    try {
      final result = await _methodChannel
          .invokeMethod<bool>('isAccessibilityEnabled');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> requestAccessibilityPermission() async {
    await _methodChannel.invokeMethod('openAccessibilitySettings');
  }

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
    await _methodChannel.invokeMethod('openAccessibilitySettings');
  }

  @override
  Future<void> requestOverlayPermission() async {
    await FlutterOverlayWindow.requestPermission();
  }

  // ── Blocking ─────────────────────────────────────
  @override
  Future<void> blockApp(String packageName) async {
    await _showBlockScreen(packageName);
  }


  @override
  Future<void> unblockApp(String packageName) async {
    _overlayShowing = false; // 👈 reset when unblocked
    await FlutterOverlayWindow.closeOverlay();
  }

  Future<void> _showBlockScreen(String packageName) async {
    try {
      await _blockChannel.invokeMethod('showBlockScreen', {
        'packageName': packageName,
      });
      debugPrint('🟢 block screen launched for: $packageName');
    } catch (e) {
      debugPrint('❌ block screen failed: $e');
    }
  }

  @override
  Future<bool> isMonitoring(String packageName) async {
    return _monitoredApps.containsKey(packageName);
  }

  @override
  Future<int> getUsedMinutesToday(String packageName) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final usage = await AppUsage().getAppUsage(startOfDay, now);
      final matches = usage.where((u) => u.packageName == packageName);
      if (matches.isEmpty) return 0;
      return matches.first.usage.inMinutes;
    } catch (e) {
      return 0;
    }
  }

  @override
  Stream<AppUsageEvent> get usageEvents => _eventController.stream;
}