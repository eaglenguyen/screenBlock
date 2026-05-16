import 'dart:async';
import 'package:app_usage/app_usage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'blocking_service.dart';

class AndroidBlockingService implements BlockingService {

  // ── Channels ─────────────────────────────────────
  static const _methodChannel = MethodChannel(
    'com.example.screenblock/accessibility',
  );
  static const _eventChannel = EventChannel(
    'com.example.screenblock/foreground_app',
  );
  static const _blockChannel = MethodChannel(
    'com.example.screenblock/block',
  );

  // ── State ─────────────────────────────────────────
  final _eventController = StreamController<AppUsageEvent>.broadcast();
  final Map<String, int> _monitoredApps = {};
  StreamSubscription? _foregroundAppSubscription;
  bool _overlayShowing = false;
  String _blockingMode = 'specific_apps';
  final Set<String> _temporarilyExempted = {};
  bool _methodHandlerRegistered = false;


  // ── BlockingService interface ─────────────────────

  @override
  Stream<AppUsageEvent> get usageEvents => _eventController.stream;

  // ── Monitoring ────────────────────────────────────

  @override
  Future<void> startMonitoring(
      String packageName,
      int limitMinutes,
      ) async {
    debugPrint('🟡 startMonitoring: $packageName');
    _monitoredApps[packageName] = limitMinutes;
    _overlayShowing = false;
    _startListening();
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
    _overlayShowing = false;
    _blockingMode = 'specific_apps';
    _foregroundAppSubscription?.cancel();
    _foregroundAppSubscription = null;
  }

  @override
  Future<bool> isMonitoring(String packageName) async {
    return _monitoredApps.containsKey(packageName);
  }

  // ── Blocking ──────────────────────────────────────

  @override
  Future<void> blockApp(String packageName) async {
    await _showBlockScreen(packageName);
  }

  @override
  Future<void> unblockApp(String packageName) async {
    _overlayShowing = false;
    await FlutterOverlayWindow.closeOverlay();
  }

  @override
  void resetOverlayState() {
    debugPrint('🟡 resetOverlayState called');
    _overlayShowing = false;
  }

  @override
  void setBlockingMode(String mode) {
    debugPrint('🟡 blockingMode set to: $mode');
    _blockingMode = mode;
  }


  // ── Permissions ───────────────────────────────────

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
    return FlutterOverlayWindow.isPermissionGranted();
  }

  @override
  Future<void> requestUsageStatsPermission() async {
    await _methodChannel.invokeMethod('openAccessibilitySettings');
  }

  @override
  Future<void> requestOverlayPermission() async {
    await FlutterOverlayWindow.requestPermission();
  }

  @override
  Future<int> getUsedMinutesToday(String packageName) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final usage = await AppUsage().getAppUsage(startOfDay, now);
      final matches = usage.where(
            (u) => u.packageName == packageName,
      );
      if (matches.isEmpty) return 0;
      return matches.first.usage.inMinutes;
    } catch (e) {
      return 0;
    }
  }

  // ── Private ───────────────────────────────────────

  void _startListening() {
    _foregroundAppSubscription?.cancel();

    _foregroundAppSubscription = _eventChannel
        .receiveBroadcastStream()
        .listen(
          (dynamic data) {
        if (data is String) {
          _onForegroundAppChanged(data);
        }
      },
      onError: (error) {
        debugPrint('❌ event channel error: $error');
      },
    );

    // only register handler once
    if (_methodHandlerRegistered) return;
    _methodHandlerRegistered = true;

    _methodChannel.setMethodCallHandler((call) async {
      debugPrint('🟡 methodChannel received: ${call.method}');
      switch (call.method) {
        case 'onBlockDismissed':
          debugPrint('🟢 resetting _overlayShowing');
          _overlayShowing = false;
          break;
        case 'blockForDay':
          final packageName = call.arguments as String;
          debugPrint('🟡 blocking for day: $packageName');
          _eventController.add(AppUsageEvent(
            packageName: packageName,
            type: AppEventType.appBlocked,
            usedMinutes: _monitoredApps[packageName] ?? 0,
            limitMinutes: _monitoredApps[packageName] ?? 0,
          ));
          break;
      }
    });
  }

  void _onForegroundAppChanged(String packageName) {
    debugPrint('🔵 _onForegroundAppChanged: $packageName — overlayShowing: $_overlayShowing');
    if (_overlayShowing) return;

    debugPrint('🔵 _onForegroundAppChanged: $packageName');
    debugPrint('🔵 _blockingMode: $_blockingMode');
    debugPrint('🔵 _monitoredApps: $_monitoredApps');

    if (_blockingMode == 'specific_apps') {
      _handleSpecificAppsMode(packageName);
    } else {
      _handleAllAppsMode(packageName);
    }
  }

  void _handleSpecificAppsMode(String packageName) {
    if (_temporarilyExempted.contains(packageName)) return;
    if (!_monitoredApps.containsKey(packageName)) return;

    debugPrint('🟢 blocking specific app: $packageName');
    _overlayShowing = true;
    _eventController.add(AppUsageEvent(
      packageName: packageName,
      type: AppEventType.timerExpired,
      usedMinutes: 0,
      limitMinutes: _monitoredApps[packageName]!,
    ));
    _showBlockScreen(packageName);
  }

  void _handleAllAppsMode(String packageName) {
    // allow apps in monitored list, block everything else
    if (_temporarilyExempted.contains(packageName)) return;
    if (_monitoredApps.containsKey(packageName)) return;

    debugPrint('🟢 blocking non-allowed app: $packageName');
    _overlayShowing = true;
    _eventController.add(AppUsageEvent(
      packageName: packageName,
      type: AppEventType.timerExpired,
      usedMinutes: 0,
      limitMinutes: 0,
    ));
    _showBlockScreen(packageName);
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
}