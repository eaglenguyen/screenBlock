import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
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
  final Duration blockedToday;
  final bool isLoading;
  final String? error;
  final double dailyGoalHours;
  final double blockGoalHours;

  const StatsState({
    this.appStats = const [],
    this.totalUsage = Duration.zero,
    this.blockedToday = Duration.zero, // 👈
    this.isLoading = false,
    this.error,
    this.dailyGoalHours = 2.0,
    this.blockGoalHours = 1.0,
  });

  static double loadBlockGoalHours() {
    try {
      final box = Hive.box(HiveBoxNames.settings);
      return (box.get(HiveBoxNames.blockingGoalHours, defaultValue: 1.0) as num)
          .toDouble();
    } catch (_) {
      return 1.0;
    }
  }

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
    return ((remaining.inMinutes / dailyGoal.inMinutes) * 100).round();
  }

  // outer ring — screen time vs goal
  double get gaugeValue {
    if (dailyGoal.inMinutes == 0) return 0;
    return (totalUsage.inMinutes / dailyGoal.inMinutes).clamp(0.0, 1.0);
  }

  // inner ring — blocked time vs total screen time
  double get blockedGaugeValue {
    if (blockGoal.inSeconds == 0) return 0;
    return (blockedToday.inSeconds / blockGoal.inSeconds)
        .clamp(0.0, 1.0);
  }

  bool get isOverGoal => totalUsage > dailyGoal;

  Duration get blockGoal =>
      Duration(minutes: (blockGoalHours * 60).round());

  String get formattedTotal {
    final hours = totalUsage.inHours;
    final minutes = totalUsage.inMinutes % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  String get formattedBlocked {
    final hours = blockedToday.inHours;
    final minutes = blockedToday.inMinutes % 60;
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

  String get formattedBlockGoal {
    final totalMinutes = (blockGoalHours * 60).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours == 0) return '${minutes}m goal';
    if (minutes == 0) return '${hours}h goal';
    return '${hours}h ${minutes}m goal';
  }


  StatsState copyWith({
    List<AppUsageStat>? appStats,
    Duration? totalUsage,
    Duration? blockedToday,
    bool? isLoading,
    String? error,
    double? dailyGoalHours,
    double? blockGoalHours,

  }) {
    return StatsState(
      appStats: appStats ?? this.appStats,
      totalUsage: totalUsage ?? this.totalUsage,
      blockedToday: blockedToday ?? this.blockedToday,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      dailyGoalHours: dailyGoalHours ?? this.dailyGoalHours,
      blockGoalHours: blockGoalHours ?? this.blockGoalHours,

    );
  }
}