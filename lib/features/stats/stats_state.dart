import 'package:flutter/foundation.dart';
import '../../../data/models/usage_log.dart';
import '../../../data/models/streak.dart';



@immutable
class AppUsageStat {
  final String packageName;
  final String appName;
  final Duration usage;
  final double proportion; // 0.0 - 1.0 of total usage

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

  // hardcoded 2h daily goal
  static const Duration dailyGoal = Duration(hours: 2);

  const StatsState({
    this.appStats = const [],
    this.totalUsage = Duration.zero,
    this.isLoading = false,
    this.error,
  });

  // how much of goal is remaining
  Duration get remaining {
    final diff = dailyGoal - totalUsage;
    return diff.isNegative ? Duration.zero : diff;
  }

  // percentage of goal remaining 0-100
  int get percentLeft {
    if (totalUsage >= dailyGoal) return 0;
    return ((remaining.inMinutes / dailyGoal.inMinutes) * 100)
        .round();
  }

  // arc fill 0.0-1.0 — caps at 1.0 if over goal
  double get gaugeValue {
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
    final hours = dailyGoal.inHours;
    return '${hours}h goal';
  }

  StatsState copyWith({
    List<AppUsageStat>? appStats,
    Duration? totalUsage,
    bool? isLoading,
    String? error,
  }) {
    return StatsState(
      appStats: appStats ?? this.appStats,
      totalUsage: totalUsage ?? this.totalUsage,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}