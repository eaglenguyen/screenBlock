import 'package:flutter/foundation.dart';
import '../../../data/models/timer_config.dart';
import '../../../data/models/streak.dart';

@immutable
class HomeState {
  final List<TimerConfig> trackedApps;
  final Streak? streak;
  final bool isLoading;
  final String? error;

  const HomeState({
    this.trackedApps = const [],
    this.streak,
    this.isLoading = false,
    this.error,
  });

  HomeState copyWith({
    List<TimerConfig>? trackedApps,
    Streak? streak,
    bool? isLoading,
    String? error,
  }) {
    return HomeState(
      trackedApps: trackedApps ?? this.trackedApps,
      streak: streak ?? this.streak,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}