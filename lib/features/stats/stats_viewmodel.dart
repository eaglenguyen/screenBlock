import 'dart:io';

import 'package:app_usage/app_usage.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/constants/hivebox_names.dart';
import '../../providers/repository_providers.dart';
import 'stats_state.dart';

part 'stats_viewmodel.g.dart';

@riverpod
class StatsViewModel extends _$StatsViewModel {

  @override
  StatsState build() {
    return const StatsState(isLoading: true);
  }

  Future<void> loadStats() async {
    final goalHours = StatsState.loadGoalHours();
    final blockGoalHours = StatsState.loadBlockGoalHours();

    if (Platform.isIOS) {
      // iOS doesn't support AppUsage
      state = state.copyWith(
        isLoading: false,
        appStats: [],
        totalUsage: Duration.zero,
        dailyGoalHours: goalHours
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