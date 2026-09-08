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
import '../../domain/platform/android_blocking_service.dart';
import '../../providers/blocking_service_provider.dart';
import '../../providers/premium_provider.dart';
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
    bool isNew = false,
  }) async {
    try {
      final config = TimeLimitConfig(
        id: existingId ?? const Uuid().v4(),
        name: name,
        packageNames: packageNames,
        limitMinutes: limitMinutes,
        days: days,
        updatedAt: DateTime.now(),
      );
      await _repo.saveConfig(config);
      if (isNew) {
        await AnalyticsService.instance.captureOnce(AnalyticsEvents.firstBlockCreated);
      }

      if (!isNew && existingId != null) {
        if (Platform.isIOS) {
          await const MethodChannel('com.eagle.pausenow/ios_blocking')
              .invokeMethod('unshieldConfigApps', {'configId': existingId});
        } else if (Platform.isAndroid) {
          final service = ref.read(blockingServiceProvider);
          if (service is AndroidBlockingService) {
            for (final pkg in packageNames) {
              await service.clearExemption(pkg); // 👈 kept — this part worked correctly
            }
            // forceRecheckTimeLimit call removed — reverting to known-stable behavior
          }
        }
      }

      await _syncToNative();
      loadConfigs();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }


  Future<void> deleteConfig(String id) async {
    final config = _repo.getConfig(id);
    await _repo.deleteConfig(id);
    await _syncToNative();


    if (config != null && Platform.isIOS) {
      // 👇 unshield using the config's own stored tokens, before they're orphaned
      await const MethodChannel('com.eagle.pausenow/ios_blocking')
          .invokeMethod('unshieldConfigApps', {'configId': id});
    } else if (config != null && Platform.isAndroid) {
      await _unblockIfUnclaimed(config.packageNames); // Android path unchanged
    }
    loadConfigs();
  }


  Future<void> _unblockIfUnclaimed(List<String> packageNames) async {
    // Android only — iOS unshielding happens via unshieldConfigApps in deleteConfig directly
    for (final packageName in packageNames) {
      await const MethodChannel('com.eagle.pausenow/accessibility')
          .invokeMethod('unblockApp', {'packageName': packageName});
    }
  }

  // 👇 new — pushes current config list to native SharedPreferences (Android)
  Future<void> _syncToNative() async {
    final configs = _getUnlockedConfigs();
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


  List<TimeLimitConfig> _getUnlockedConfigs() {
    final isPremium = ref.read(isPremiumProvider);
    if (isPremium) return state.configs;
    return state.configs.take(1).toList(); // 👈 only the first config counts while free
  }



  bool hasActiveAppLimitToday() {
    final today = _todayIndex();
    final unlockedConfigs = _getUnlockedConfigs(); // 👈 new
    return unlockedConfigs.any((c) => c.isActive && c.days.contains(today));
  }

  int _todayIndex() {
    // DateTime.weekday: Monday=1...Sunday=7 → convert to Mon=0...Sun=6
    return DateTime.now().weekday - 1;
  }
}