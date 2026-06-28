import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
    final hasScreenTime = await _service.hasAccessibilityPermission();

    bool hasAccessibility = false;
    if (Platform.isAndroid) {
      hasAccessibility = await _service.hasAccessibilityPermission();
    }

    bool hasBattery = true;
    if (Platform.isAndroid) {
      try {
        const channel = MethodChannel('com.eagle.pausenow/accessibility');
        hasBattery = await channel.invokeMethod<bool>(
          'isBatteryOptimizationIgnored',
        ) ??
            false;
      } catch (_) {
        hasBattery = false;
      }
    }

    // 👇 check notification permission
    bool hasNotification = false;

    try {
      final plugin = FlutterLocalNotificationsPlugin();
      if (Platform.isIOS) {
        final iosPlugin = plugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        final result = await iosPlugin?.checkPermissions();
        hasNotification = result?.isEnabled ?? false;
      } else {
        final androidPlugin = plugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        hasNotification = await androidPlugin?.areNotificationsEnabled() ?? false;
      }
    } catch (_) {
      hasNotification = false;
    }

    state = state.copyWith(
      hasScreenTimePermission: hasScreenTime,
      hasAccessibilityPermission: hasAccessibility,
      hasUsagePermission: hasUsage,
      hasOverlayPermission: hasOverlay,
      hasBatteryOptimization: hasBattery,
      hasNotificationPermission: hasNotification, // 👈 add
    );
  }

  // 👇 add this method
  Future<void> requestNotificationPermission() async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      if (Platform.isIOS) {
        final iosPlugin = plugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      } else {
        final androidPlugin = plugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('❌ notification permission error: $e');
    }
    await _checkPermissions();
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
