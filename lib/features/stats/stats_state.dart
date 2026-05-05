import 'package:flutter/foundation.dart';
import '../../../data/models/usage_log.dart';
import '../../../data/models/streak.dart';

@immutable
class StatsState {
  final List<UsageLog> todayLogs;
  final Map<String, List<UsageLog>> weeklyLogs;
  final Streak? streak;
  final bool isLoading;
  final String? error;

  const StatsState({
    this.todayLogs = const [],
    this.weeklyLogs = const {},
    this.streak,
    this.isLoading = false,
    this.error,
  });

  // total minutes across all apps today
  int get totalMinutesToday => todayLogs.fold(
    0, (sum, log) => sum + log.totalMinutes,
  );

  // total hours today as a display string
  String get totalTimeToday {
    final hours = totalMinutesToday ~/ 60;
    final mins = totalMinutesToday % 60;
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }

  StatsState copyWith({
    List<UsageLog>? todayLogs,
    Map<String, List<UsageLog>>? weeklyLogs,
    Streak? streak,
    bool? isLoading,
    String? error,
  }) {
    return StatsState(
      todayLogs: todayLogs ?? this.todayLogs,
      weeklyLogs: weeklyLogs ?? this.weeklyLogs,
      streak: streak ?? this.streak,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}