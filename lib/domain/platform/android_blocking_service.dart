import 'dart:async';
import 'blocking_service.dart';

// TODO: implement with flutter_foreground_task,
// app_usage, and flutter_overlay_window
class AndroidBlockingService implements BlockingService {

  final _eventController = StreamController<AppUsageEvent>.broadcast();

  @override
  Future<void> startMonitoring(String packageName, int limitMinutes) {
    throw UnimplementedError('startMonitoring not implemented yet');
  }

  @override
  Future<void> stopMonitoring(String packageName) {
    throw UnimplementedError();
  }

  @override
  Future<void> stopAllMonitoring() {
    throw UnimplementedError();
  }

  @override
  Future<void> blockApp(String packageName) {
    throw UnimplementedError();
  }

  @override
  Future<void> unblockApp(String packageName) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isMonitoring(String packageName) {
    throw UnimplementedError();
  }

  @override
  Future<int> getUsedMinutesToday(String packageName) {
    throw UnimplementedError();
  }

  @override
  Future<bool> hasUsageStatsPermission() {
    throw UnimplementedError();
  }

  @override
  Future<bool> hasOverlayPermission() {
    throw UnimplementedError();
  }

  @override
  Future<void> requestUsageStatsPermission() {
    throw UnimplementedError();
  }

  @override
  Future<void> requestOverlayPermission() {
    throw UnimplementedError();
  }

  @override
  Stream<AppUsageEvent> get usageEvents => _eventController.stream;
}