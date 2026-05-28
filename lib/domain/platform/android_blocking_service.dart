import 'dart:async';
import 'package:app_usage/app_usage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'blocking_service.dart';

class AndroidBlockingService implements BlockingService {

  static const _methodChannel = MethodChannel(
    'com.eagle.screenblock/accessibility',
  );
  static const _eventChannel = EventChannel(
    'com.eagle.screenblock/foreground_app',
  );
  static const _blockChannel = MethodChannel(
    'com.eagle.screenblock/block',
  );

  final _eventController = StreamController<AppUsageEvent>.broadcast();
  final Map<String, int> _monitoredApps = {};
  StreamSubscription? _foregroundAppSubscription;
  bool _overlayShowing = false;
  String _blockingMode = 'specific_apps';
  final Set<String> _temporarilyExempted = {};
  bool _methodHandlerRegistered = false;

  @override
  Stream<AppUsageEvent> get usageEvents => _eventController.stream;

  // ── Native SharedPreferences ──────────────────────

  Future<void> _saveNativeBlockingState({required bool isBlocking}) async {
    try {
      await _methodChannel.invokeMethod('saveBlockingState', {
        'isBlocking': isBlocking,
        'mode': _blockingMode,
        'apps': _monitoredApps.keys.toList(),
      });
      debugPrint('💾 native state saved: isBlocking=$isBlocking apps=${_monitoredApps.keys.toList()}');
    } catch (e) {
      debugPrint('❌ saveNativeBlockingState error: $e');
    }
  }

  // ── Flutter SharedPreferences ─────────────────────

  Future<void> persistBlockingState({
    int sessionMinutes = 30,
    String sessionType = 'manual',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isBlocking', true);
    await prefs.setString('sessionType', sessionType);
    await prefs.setString('blockingMode', _blockingMode);
    await prefs.setStringList('monitoredApps', _monitoredApps.keys.toList());
    await prefs.setString('monitoredLimits', _monitoredApps.values.join(','));
    await prefs.setInt('sessionStartTime', DateTime.now().millisecondsSinceEpoch);
    await prefs.setInt('sessionMinutes', sessionMinutes);

    // save to native prefs for Kotlin direct access when app is killed
    await _saveNativeBlockingState(isBlocking: true);

    debugPrint('💾 persistBlockingState: sessionType=$sessionType sessionMinutes=$sessionMinutes');
  }

  Future<void> _restoreBlockingState() async {
    final prefs = await SharedPreferences.getInstance();
    final isBlocking = prefs.getBool('isBlocking') ?? false;
    if (!isBlocking) return;

    final mode = prefs.getString('blockingMode') ?? 'specific_apps';
    final apps = prefs.getStringList('monitoredApps') ?? [];
    final limits = prefs.getString('monitoredLimits') ?? '';
    final limitList = limits.split(',')
        .map((e) => int.tryParse(e) ?? 30)
        .toList();

    _blockingMode = mode;
    for (int i = 0; i < apps.length; i++) {
      _monitoredApps[apps[i]] = i < limitList.length ? limitList[i] : 30;
    }
    debugPrint('🔄 Restored blocking state: $_monitoredApps');
  }

  // ── Monitoring ────────────────────────────────────

  @override
  Future<void> startMonitoring(
      String packageName,
      int limitMinutes,
      ) async {
    if (_monitoredApps.isEmpty) {
      await _restoreBlockingState();
    }
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
    debugPrint('🔴 stopAllMonitoring called');
    debugPrint(StackTrace.current.toString());
    _monitoredApps.clear();
    _overlayShowing = false;
    _blockingMode = 'specific_apps';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isBlocking', false);
    await prefs.remove('monitoredApps');
    await prefs.remove('monitoredLimits');
    await prefs.remove('sessionStartTime');

    // clear native state
    await _saveNativeBlockingState(isBlocking: false);

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
      final matches = usage.where((u) => u.packageName == packageName);
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

    if (_methodHandlerRegistered) return;
    _methodHandlerRegistered = true;

    _methodChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onBlockDismissed':
          debugPrint('🟢 onBlockDismissed — resetting _overlayShowing');
          _overlayShowing = false;
          break;
        case 'blockForDay':
          final packageName = call.arguments as String;
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
    if (_overlayShowing) return;

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