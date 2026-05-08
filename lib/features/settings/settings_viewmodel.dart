import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../domain/platform/blocking_service.dart';
import '../../../providers/blocking_service_provider.dart';
import 'settings_state.dart';

part 'settings_viewmodel.g.dart';

@riverpod
class SettingsViewModel extends _$SettingsViewModel {

  @override
  SettingsState build() {
    Future.microtask(() => _checkPermissions());
    return const SettingsState();
  }

  BlockingService get _service =>
      ref.read(blockingServiceProvider);

  Future<void> _checkPermissions() async {
    final hasUsage = await _service.hasUsageStatsPermission();
    final hasOverlay = await _service.hasOverlayPermission();
    state = state.copyWith(
      hasUsagePermission: hasUsage,
      hasOverlayPermission: hasOverlay,
    );
  }

  Future<void> requestUsagePermission() async {
    await _service.requestUsageStatsPermission();
    await _checkPermissions();
  }

  Future<void> requestOverlayPermission() async {
    await _service.requestOverlayPermission();
    await _checkPermissions();
  }

  Future<void> requestBatteryOptimization() async {
    // TODO: implement with android_intent_plus package
    await _checkPermissions();
  }

  Future<void> resetDailyRecord() async {
    // TODO: clear today's usage logs from Hive
  }

  Future<void> restorePurchases() async {
    // TODO: RevenueCat restore
  }
}