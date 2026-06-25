import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../domain/platform/blocking_service.dart';
import '../../../providers/blocking_service_provider.dart';
import '../../core/constants/hivebox_names.dart';
import '../../data/models/block_session.dart';
import '../../providers/premium_provider.dart';
import '../../services/revenuecat_service.dart';
import '../home/home_viewmodel.dart';
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


  Future<void> requestAccessibilityPermission() async {
    final service = ref.read(blockingServiceProvider);
    await service.requestAccessibilityPermission();
    await checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final hasUsage = await _service.hasUsageStatsPermission();
    final hasOverlay = await _service.hasOverlayPermission();
    final hasScreenTime = await _service.hasAccessibilityPermission(); // 👈 add

    bool hasAccessibility = false;
    if (Platform.isAndroid) {
      hasAccessibility = await _service.hasAccessibilityPermission();
    }
    bool hasBattery = true; // iOS always true
    if (Platform.isAndroid) {
      // check via method channel since there's no Flutter API for this
      try {
        const channel = MethodChannel('com.eagle.pausenow/accessibility');
        hasBattery = await channel.invokeMethod<bool>(
            'isBatteryOptimizationIgnored',
        ) ?? false;
      } catch (_) {
        hasBattery = false;
      }
    }

    state = state.copyWith(
      hasScreenTimePermission: hasScreenTime, // 👈 add
      hasAccessibilityPermission: hasAccessibility, // 👈 add
      hasUsagePermission: hasUsage,
      hasOverlayPermission: hasOverlay,
      hasBatteryOptimization: hasBattery,
    );
  }

  Future<void> checkPermissions() async => _checkPermissions(); // 👈 expose publicly


  Future<void> requestUsagePermission() async {
    await _service.requestUsageStatsPermission();
    await _checkPermissions();
  }

  Future<void> requestOverlayPermission() async {
    await _service.requestOverlayPermission();
    await _checkPermissions();
  }

  Future<void> requestBatteryOptimization() async {
    if (!Platform.isAndroid) return;

    const intent = AndroidIntent(
      action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
      data: 'package:com.eagle.pausenow',
      flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
    );

    await intent.launch();
    await _checkPermissions();
  }

  Future<void> resetDailyRecord() async {
    final box = Hive.box<BlockSession>(HiveBoxNames.blockSessions);
    final today = DateTime.now();
    final keysToDelete = box.keys.where((key) {
      final session = box.get(key);
      if (session == null) return false;
      return session.startTime.year == today.year &&
          session.startTime.month == today.month &&
          session.startTime.day == today.day;
    }).toList();

    for (final key in keysToDelete) {
      await box.delete(key);
    }

    // 👇 reload blocked time in home screen
    ref.read(homeViewModelProvider.notifier).loadTodayBlockedTime();
  }

  Future<void> restorePurchases() async {
      try {
        final restored = await RevenueCatService.instance.restorePurchases();
        if (restored) {
          // invalidate so isPremiumProvider re-fetches
          ref.invalidate(premiumProvider);
          state = state.copyWith(isPremium: true);
        } else {
          // nothing to restore
          if (state.appVersion.isNotEmpty) {
            state = state.copyWith(isPremium: false);
          }
        }
      } catch (e) {
        debugPrint('❌ restorePurchases error: $e');
      }
    }
}
