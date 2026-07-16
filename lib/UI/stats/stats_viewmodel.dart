import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:app_usage/app_usage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../providers/repository_providers.dart';
import 'stats_state.dart';

part 'stats_viewmodel.g.dart';

@riverpod
class StatsViewModel extends _$StatsViewModel {

  @override
  StatsState build() {
    return const StatsState(isLoading: true);
  }

  Future<double> getTotalSecondsForDay(DateTime day) async {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = _isSameDay(day, DateTime.now())
        ? DateTime.now()
        : DateTime(day.year, day.month, day.day, 23, 59, 59);

    final usageList = await AppUsage().getAppUsage(startOfDay, endOfDay);

    final filtered = usageList.where((u) =>
    u.usage.inMinutes > 0 &&
        u.usage.inHours < 24 &&
        !_isSystemApp(u.packageName));

    final total = filtered.fold(Duration.zero, (sum, u) => sum + u.usage);
    return total.inSeconds.toDouble();
  }

  Future<void> loadAppUsageForDay(DateTime day) async {
    if (!Platform.isAndroid) return;

    state = state.copyWith(isLoadingAppList: true); // 👈 new field, see state update below

    try {
      final startOfDay = DateTime(day.year, day.month, day.day);
      final endOfDay = _isSameDay(day, DateTime.now())
          ? DateTime.now() // today — cap at "now"
          : DateTime(day.year, day.month, day.day, 23, 59, 59); // past day — full day

      final usageList = await AppUsage().getAppUsage(startOfDay, endOfDay);

      final filtered = usageList.where((u) =>
      u.usage.inMinutes > 0 &&
          u.usage.inHours < 24 &&
          !_isSystemApp(u.packageName)).toList();

      filtered.sort((a, b) => b.usage.compareTo(a.usage));

      final total = filtered.fold(Duration.zero, (sum, u) => sum + u.usage);

      final stats = filtered.map((u) {
        final proportion = total.inSeconds > 0 ? u.usage.inSeconds / total.inSeconds : 0.0;
        return AppUsageStat(
          packageName: u.packageName,
          appName: _formatAppName(u.appName),
          usage: u.usage,
          proportion: proportion,
        );
      }).toList();

      state = state.copyWith(
        selectedDayAppStats: stats, // 👈 new field, separate from appStats (today's default)
        isLoadingAppList: false,
      );
    } catch (e) {
      debugPrint('❌ loadAppUsageForDay error: $e');
      state = state.copyWith(isLoadingAppList: false);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> loadStats() async {
    final goalHours = StatsState.loadGoalHours();
    final blockGoalHours = StatsState.loadBlockGoalHours();

    if (Platform.isIOS) {
      final blockedDuration = ref
          .read(blockSessionRepositoryProvider)
          .getTodayTotalDuration();

      double totalScreenTimeSeconds = 0;
      try {
        final result = await const MethodChannel('com.eagle.pausenow/ios_blocking')
            .invokeMethod<Map>('getScreenTimeTotal'); // 👈 Map not double

        final total = (result?['total'] as num?)?.toDouble() ?? 0.0;
        final date = result?['date'] as String? ?? '';
        final today = DateTime.now().toIso8601String().substring(0, 10);

        if (date == today) {
          totalScreenTimeSeconds = total;
          debugPrint('📊 screen time: $totalScreenTimeSeconds seconds');
        } else {
          debugPrint('📊 stale data — date: $date today: $today');
        }
      } catch (e) {
        debugPrint('❌ getScreenTimeTotal error: $e');
      }

      state = state.copyWith(
        isLoading: false,
        appStats: [],
        totalUsage: Duration(seconds: totalScreenTimeSeconds.round()),
        blockedToday: blockedDuration,
        dailyGoalHours: goalHours,
        blockGoalHours: blockGoalHours,
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(
        now.year,
        now.month,
        now.day,
      );

      // fetch usage for today
      final usageList = await AppUsage().getAppUsage(
        startOfDay,
        now,
      );

      // filter out system apps and zero usage
      final filtered = usageList.where((u) =>
      u.usage.inMinutes > 0 &&
          u.usage.inHours < 24 &&
          !_isSystemApp(u.packageName)).toList();

      // sort by usage descending
      filtered.sort((a, b) => b.usage.compareTo(a.usage));

      // calculate total
      final total = filtered.fold(
        Duration.zero,
            (sum, u) => sum + u.usage,
      );

      // cap total at 24 hours
      final cappedTotal = total.inHours >= 24
          ? const Duration(hours: 24)
          : total; // 👈 never show more than 24h


      // build app stats with proportions
      final stats = filtered.map((u) {
        final proportion = total.inSeconds > 0
            ? u.usage.inSeconds / total.inSeconds
            : 0.0;

        return AppUsageStat(
          packageName: u.packageName,
          appName: _formatAppName(u.appName),
          usage: u.usage,
          proportion: proportion,
        );
      }).toList();

      final blockedDuration = await ref
          .read(blockSessionRepositoryProvider)
          .getTodayTotalDuration();

      state = state.copyWith(
          appStats: stats,
          totalUsage: cappedTotal,
          isLoading: false,
          dailyGoalHours: goalHours,
          blockGoalHours: blockGoalHours,
          blockedToday: blockedDuration
      );
    } catch (e) {
      debugPrint('❌ stats load error: $e');
      final isPermission = e.toString().contains('SecurityException') ||
          e.toString().contains('permission');
      state = state.copyWith(
        isLoading: false,
        error: isPermission ? 'permission denied' : e.toString(),
      );
    }
  }

  Future<void> requestUsagePermission() async {
    if (Platform.isAndroid) {
      const intent = AndroidIntent(
        action: 'android.settings.USAGE_ACCESS_SETTINGS',
      );
      await intent.launch();
    }
  }

  // ── Helpers ──────────────────────────────────────

  bool _isSystemApp(String packageName) {
    const systemPrefixes = [
      'com.android',
      'com.google.android',
      'android',
      'com.samsung',
      'com.sec',
      'com.qualcomm',
      'com.miui',
      'com.huawei',
      'com.oneplus',
      'com.pixel',
    ];
    return systemPrefixes.any(
          (prefix) => packageName.startsWith(prefix),
    );
  }

  String _formatAppName(String name) {
    if (name.isEmpty) return 'Unknown';
    // capitalize first letter
    return name[0].toUpperCase() + name.substring(1);
  }
}