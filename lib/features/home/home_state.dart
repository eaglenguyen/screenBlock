import 'package:flutter/foundation.dart';
import '../../../data/models/timer_config.dart';
import '../../../data/models/streak.dart';


enum BlockingPhase {
  idle,        // default — shows normal timer card
  countdown,   // 3 second countdown
  active,      // actively blocking with timer
  onBreak,     // break in progress
}


@immutable
class HomeState {
  final List<TimerConfig> trackedApps;
  final Streak? streak;
  final bool isLoading;
  final String? error;
  final String blockingType; // 'all_apps' or 'specific_apps'
  final List<String> blockedApps;
  final List<String> allowedApps;
  final int selectedMinutes;
  final BlockingPhase phase;
  final int remainingSeconds;
  final int breakRemainingSeconds;

  const HomeState({
    this.trackedApps = const [],
    this.streak,
    this.isLoading = false,
    this.error,
    this.blockingType = 'all_apps',
    this.blockedApps = const [],
    this.allowedApps = const [],
    this.selectedMinutes = 30,
    this.phase = BlockingPhase.idle,
    this.remainingSeconds = 0,
    this.breakRemainingSeconds = 0,
  });

  bool get isBlocking =>
      phase == BlockingPhase.active ||
          phase == BlockingPhase.countdown ||
          phase == BlockingPhase.onBreak;

  String get formattedTime {
    final h = (remainingSeconds ~/ 3600)
        .toString().padLeft(2, '0');
    final m = ((remainingSeconds % 3600) ~/ 60)
        .toString().padLeft(2, '0');
    final s = (remainingSeconds % 60)
        .toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  HomeState copyWith({
    List<TimerConfig>? trackedApps,
    Streak? streak,
    bool? isLoading,
    String? error,
    String? blockingType,
    List<String>? blockedApps,
    List<String>? allowedApps,
    int? selectedMinutes,
    BlockingPhase? phase,
    int? remainingSeconds,
    int? breakRemainingSeconds,
  }) {
    return HomeState(
      trackedApps: trackedApps ?? this.trackedApps,
      streak: streak ?? this.streak,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      blockingType: blockingType ?? this.blockingType,
      blockedApps: blockedApps ?? this.blockedApps,
      allowedApps: allowedApps ?? this.allowedApps,
      selectedMinutes: selectedMinutes ?? this.selectedMinutes,
      phase: phase ?? this.phase,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      breakRemainingSeconds:
      breakRemainingSeconds ?? this.breakRemainingSeconds,
    );
  }


}