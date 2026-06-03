import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../../data/models/usage_log.dart';
import '../../../data/models/streak.dart';
import '../../../core/constants/hivebox_names.dart';

@immutable
class AppUsageStat {
  final String packageName;
  final String appName;
  final Duration usage;
  final double proportion;

  const AppUsageStat({
    required this.packageName,
    required this.appName,
    required this.usage,
    required this.proportion,
  });

  String get formattedTime {
    final hours = usage.inHours;
    final minutes = usage.inMinutes % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}

@immutable
class StatsState {
  final List<AppUsageStat> appStats;
  final Duration totalUsage;
  final bool isLoading;
  final String? error;
  final double dailyGoalHours; // 👈 now dynamic from Hive

  const StatsState({
    this.appStats = const [],
    this.totalUsage = Duration.zero,
    this.isLoading = false,
    this.error,
    this.dailyGoalHours = 2.0, // default 2 hours
  });

  // read goal from Hive — falls back to 2h
  static double loadGoalHours() {
    try {
      final box = Hive.box(HiveBoxNames.settings);
      return (box.get('dailyScreenTimeGoal', defaultValue: 2.0) as num)
          .toDouble();
    } catch (_) {
      return 2.0;
    }
  }

  Duration get dailyGoal =>
      Duration(minutes: (dailyGoalHours * 60).round());

  Duration get remaining {
    final diff = dailyGoal - totalUsage;
    return diff.isNegative ? Duration.zero : diff;
  }

  int get percentLeft {
    if (totalUsage >= dailyGoal) return 0;
    return ((remaining.inMinutes / dailyGoal.inMinutes) * 100)
        .round();
  }

  double get gaugeValue {
    if (dailyGoal.inMinutes == 0) return 0;
    return (totalUsage.inMinutes / dailyGoal.inMinutes)
        .clamp(0.0, 1.0);
  }

  bool get isOverGoal => totalUsage > dailyGoal;

  String get formattedTotal {
    final hours = totalUsage.inHours;
    final minutes = totalUsage.inMinutes % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  String get formattedGoal {
    final totalMinutes = (dailyGoalHours * 60).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours == 0) return '${minutes}m goal';
    if (minutes == 0) return '${hours}h goal';
    return '${hours}h ${minutes}m goal';
  }

  StatsState copyWith({
    List<AppUsageStat>? appStats,
    Duration? totalUsage,
    bool? isLoading,
    String? error,
    double? dailyGoalHours,
  }) {
    return StatsState(
      appStats: appStats ?? this.appStats,
      totalUsage: totalUsage ?? this.totalUsage,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      dailyGoalHours: dailyGoalHours ?? this.dailyGoalHours,
    );
  }
}