import 'dart:convert'; // 👈 new — for jsonEncode
import 'dart:io'; // 👈 new — for Platform.isAndroid
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart'; // 👈 new — for MethodChannel
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../data/models/time_limit_config.dart';
import '../../../providers/repository_providers.dart';
import '../../data/repositories/TimeLimitRepo.dart';
import 'data/app_limit_conflict.dart';
import 'time_limit_state.dart';

part 'time_limit_viewmodel.g.dart';

@riverpod
class TimeLimitViewModel extends _$TimeLimitViewModel {

  TimeLimitRepository get _repo => ref.read(timeLimitRepositoryProvider);

  @override
  TimeLimitState build() {
    Future.microtask(() => loadConfigs());
    return const TimeLimitState(isLoading: true);
  }

  void loadConfigs() {
    try {
      final configs = _repo.getAllConfigs();
      state = state.copyWith(configs: configs, isLoading: false);
    } catch (e) {
      debugPrint('❌ loadConfigs error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> saveConfig({
    String? existingId,
    required String name,
    required List<String> packageNames,
    required int limitMinutes,
    required List<int> days,
  }) async {
    try {
      final isNewConfig = existingId == null;

      final config = TimeLimitConfig(
        id: existingId ?? const Uuid().v4(),
        name: name,
        packageNames: packageNames,
        limitMinutes: limitMinutes,
        days: days,
      );

      await _repo.saveConfig(config);

      if (isNewConfig) {
        await AnalyticsService.instance.captureOnce(AnalyticsEvents.firstBlockCreated);
      }

      await _syncToNative(); // 👈 new
      loadConfigs();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteConfig(String id) async {
    await _repo.deleteConfig(id);
    await _syncToNative(); // 👈 new
    loadConfigs();
  }

  Future<void> toggleConfig(String id) async {
    final config = _repo.getConfig(id);
    if (config == null) return;
    final updated = config.copyWith(isActive: !config.isActive);
    await _repo.saveConfig(updated);
    await _syncToNative(); // 👈 new
    loadConfigs();
  }

  // 👇 new — pushes current config list to native SharedPreferences (Android)
  Future<void> _syncToNative() async {
    final configs = _repo.getAllConfigs();

    if (Platform.isAndroid) {
      final json = jsonEncode(configs.map((c) => {
        'packageNames': c.packageNames,
        'limitMinutes': c.limitMinutes,
        'days': c.days,
        'isActive': c.isActive,
      }).toList());

      await const MethodChannel('com.eagle.pausenow/accessibility')
          .invokeMethod('saveTimeLimitConfigs', {'configsJson': json});
    } else if (Platform.isIOS) {
      for (final config in configs) {
        await const MethodChannel('com.eagle.pausenow/ios_blocking')
            .invokeMethod('saveTimeLimitDays', {
          'configId': config.id,
          'daysJson': jsonEncode(config.days),
        });
      }

      await const MethodChannel('com.eagle.pausenow/ios_blocking')
          .invokeMethod('syncTimeLimitConfigs', {
        'configs': configs.map((c) => {
          'id': c.id,
          'limitMinutes': c.limitMinutes,
          'isActive': c.isActive,
        }).toList(),
      });
    }
  }

  AppLimitConflict? findAppLimitConflict({
    required String packageName,
    required List<int> selectedDays,
    String? excludeConfigId,
  }) {
    // check against schedules
    final schedules = ref.read(scheduleRepositoryProvider).getAllSchedules();
    for (final schedule in schedules) {
      final scheduleApps = {...schedule.blockedApps, ...schedule.allowedApps};
      if (!scheduleApps.contains(packageName)) continue;
      if (schedule.days.any((d) => selectedDays.contains(d))) {
        return AppLimitConflict(name: schedule.name, source: 'schedule');
      }
    }

    // check against other time-limit configs
    final existingConfigs = _repo.getConfigsContainingApp(packageName);
    for (final config in existingConfigs) {
      if (config.id == excludeConfigId) continue;
      if (config.days.any((d) => selectedDays.contains(d))) {
        return AppLimitConflict(name: config.name, source: 'time_limit');
      }
    }

    return null;
  }

  bool hasActiveAppLimitToday() {
    final today = _todayIndex();
    return state.configs.any((c) => c.isActive && c.days.contains(today));
  }

  int _todayIndex() {
    // DateTime.weekday: Monday=1...Sunday=7 → convert to Mon=0...Sun=6
    return DateTime.now().weekday - 1;
  }
}