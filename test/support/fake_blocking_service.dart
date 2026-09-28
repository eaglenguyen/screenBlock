import 'dart:async';

import 'package:pausenow/domain/blocking_service.dart';

/// Minimal in-memory [BlockingService] for tests — no platform channels.
///
/// Permission flags start false; the `request*` methods flip the matching
/// flag to true, mirroring the "request → OS grants it → recheck" flow the
/// real platform services drive asynchronously.
class FakeBlockingService implements BlockingService {
  bool usageStatsGranted = false;
  bool overlayGranted = false;
  bool accessibilityGranted = false;

  final List<String> calls = [];

  final _controller = StreamController<AppUsageEvent>.broadcast();

  final Map<String, int> monitored = {};
  String blockingMode = 'specific_apps';

  @override
  Stream<AppUsageEvent> get usageEvents => _controller.stream;

  @override
  Future<void> startMonitoring(String packageName, int limitMinutes) async {
    calls.add('startMonitoring');
    monitored[packageName] = limitMinutes;
  }

  @override
  Future<void> stopMonitoring(String packageName) async {
    calls.add('stopMonitoring');
    monitored.remove(packageName);
  }

  @override
  Future<void> stopAllMonitoring() async {
    calls.add('stopAllMonitoring');
    monitored.clear();
  }

  @override
  Future<void> blockApp(String packageName) async {
    calls.add('blockApp');
  }

  @override
  Future<void> unblockApp(String packageName) async {
    calls.add('unblockApp');
  }

  @override
  Future<bool> isMonitoring(String packageName) async {
    return monitored.containsKey(packageName);
  }

  @override
  Future<int> getUsedMinutesToday(String packageName) async => 0;

  @override
  void resetOverlayState() {
    calls.add('resetOverlayState');
  }

  @override
  void setBlockingMode(String mode) {
    calls.add('setBlockingMode');
    blockingMode = mode;
  }

  @override
  Future<bool> hasUsageStatsPermission() async => usageStatsGranted;

  @override
  Future<bool> hasOverlayPermission() async => overlayGranted;

  @override
  Future<void> requestUsageStatsPermission() async {
    calls.add('requestUsageStatsPermission');
    usageStatsGranted = true;
  }

  @override
  Future<void> requestOverlayPermission() async {
    calls.add('requestOverlayPermission');
    overlayGranted = true;
  }

  @override
  Future<bool> hasAccessibilityPermission() async => accessibilityGranted;

  @override
  Future<void> requestAccessibilityPermission() async {
    calls.add('requestAccessibilityPermission');
    accessibilityGranted = true;
  }

  void dispose() => _controller.close();
}
