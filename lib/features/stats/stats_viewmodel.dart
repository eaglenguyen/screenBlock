import 'dart:io';

import 'package:app_usage/app_usage.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'stats_state.dart';

part 'stats_viewmodel.g.dart';

@riverpod
class StatsViewModel extends _$StatsViewModel {

  @override
  StatsState build() {
    return const StatsState(isLoading: true);
  }

  Future<void> loadStats() async {
    if (Platform.isIOS) {
      // iOS doesn't support AppUsage
      state = state.copyWith(
        isLoading: false,
        appStats: [],
        totalUsage: Duration.zero,
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
          !_isSystemApp(u.packageName)).toList();

      // sort by usage descending
      filtered.sort((a, b) => b.usage.compareTo(a.usage));

      // calculate total
      final total = filtered.fold(
        Duration.zero,
            (sum, u) => sum + u.usage,
      );

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

      state = state.copyWith(
        appStats: stats,
        totalUsage: total,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('❌ stats load error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
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