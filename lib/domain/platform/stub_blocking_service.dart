import 'dart:async';
import 'package:flutter/cupertino.dart';

import 'blocking_service.dart';

class StubBlockingService implements BlockingService {

  // in-memory fake state
  final Map<String, int> _monitoredApps = {};
  final _eventController = StreamController<AppUsageEvent>.broadcast();

  @override
  Future<void> startMonitoring(
      String packageName,
      int limitMinutes,
      ) async {
    _monitoredApps[packageName] = limitMinutes;
    debugLog('startMonitoring: $packageName ($limitMinutes mins)');
  }

  @override
  Future<void> stopMonitoring(String packageName) async {
    _monitoredApps.remove(packageName);
    debugLog('stopMonitoring: $packageName');
  }

  @override
  Future<void> stopAllMonitoring() async {
    _monitoredApps.clear();
    debugLog('stopAllMonitoring called');
  }

  @override
  Future<void> blockApp(String packageName) async {
    debugLog('blockApp: $packageName');
    // emit a fake event so UI can react
    _eventController.add(AppUsageEvent(
      packageName: packageName,
      type: AppEventType.appBlocked,
      usedMinutes: _monitoredApps[packageName] ?? 0,
      limitMinutes: _monitoredApps[packageName] ?? 30,
    ));
  }

  @override
  Future<void> unblockApp(String packageName) async {
    debugLog('unblockApp: $packageName');
  }

  @override
  Future<bool> isMonitoring(String packageName) async {
    return _monitoredApps.containsKey(packageName);
  }

  @override
  Future<int> getUsedMinutesToday(String packageName) async {
    // return fake usage data so stats screen
    // has something to show during development
    final fakeUsage = {
      'com.instagram.android': 45,
      'com.facebook.katana': 20,
      'com.zhiliaoapp.musically': 60,
      'com.google.android.youtube': 35,
    };
    return fakeUsage[packageName] ?? 10;
  }

  @override
  Future<bool> hasUsageStatsPermission() async {
    // pretend permissions are granted
    // so permission screens don't block dev flow
    return true;
  }

  @override
  Future<bool> hasOverlayPermission() async {
    return true;
  }

  @override
  Future<void> requestUsageStatsPermission() async {
    debugLog('requestUsageStatsPermission called');
  }

  @override
  Future<void> requestOverlayPermission() async {
    debugLog('requestOverlayPermission called');
  }

  @override
  Stream<AppUsageEvent> get usageEvents => _eventController.stream;

  // ── Test helper ─────────────────────────────────
  // call this from a button during dev to simulate
  // a timer expiring so you can test the overlay UI
  void simulateTimerExpired(String packageName) {
    _eventController.add(AppUsageEvent(
      packageName: packageName,
      type: AppEventType.timerExpired,
      usedMinutes: 30,
      limitMinutes: 30,
    ));
  }

  void debugLog(String msg) {
    // ignore: avoid_print
    print('[StubBlockingService] $msg');
  }

  void dispose() {
    _eventController.close();
  }

  @override
  Future<bool> hasAccessibilityPermission() {
    // TODO: implement hasAccessibilityPermission
    throw UnimplementedError();
  }

  @override
  Future<void> requestAccessibilityPermission() {
    // TODO: implement requestAccessibilityPermission
    throw UnimplementedError();
  }

  @override
  void resetOverlayState() {
    // TODO: implement resetOverlayState
  }

  @override
  void setBlockingMode(String mode) {
    debugPrint('[StubBlockingService] setBlockingMode: $mode');
  }
}