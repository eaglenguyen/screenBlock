import 'package:flutter/foundation.dart';
import 'package:pausenow/UI/home/timer/pomodoro_sheet.dart';
import '../../../data/models/timer_config.dart';
import '../../../data/models/streak.dart';
import '../../core/constants/app_constants.dart';


enum BlockingPhase {
  idle,        // default — shows normal timer card
  countdown,   // 3 second countdown
  active,      // actively blocking with timer
  onBreak,     // break in progress
  completed,
  claimXp,
}


@immutable
class HomeState {
  final List<TimerConfig> trackedApps;
  final bool isLoading;
  final String? error;
  final String blockingType; // 'all_apps' or 'specific_apps'
  final List<String> blockedApps;
  final List<String> allowedApps;
  final int selectedMinutes;
  final BlockingPhase phase;
  final int remainingSeconds;
  final int breakRemainingSeconds;

  final String? activeSessionKey;
  final Duration todayBlockedTime;
  final int xpEarned;
  final int totalXp;

  final DateTime? sessionStartTime;
  final DateTime? breakStartTime;
  final DateTime? countdownStartTime;
  final int originalBreakSeconds;
  final bool shouldAnimateBlockedTime;
  final bool isScheduleActive;
  final bool isSchedulePaused;
  final int schedulePauseRemainingSeconds;

  final PomodoroConfig pomodoroConfig;
  final int pomodoroRoundCount;




  const HomeState({
    this.trackedApps = const [],
    this.isLoading = false,
    this.error,
    this.blockingType = AppConstants.blockingTypeSpecificApps, // keep const default
    this.blockedApps = const [],
    this.allowedApps = const [],
    this.selectedMinutes = 30,
    this.phase = BlockingPhase.idle,
    this.remainingSeconds = 0,
    this.breakRemainingSeconds = 0,
    this.activeSessionKey,
    this.todayBlockedTime = Duration.zero,
    this.xpEarned = 0,
    this.totalXp = 0,
    this.sessionStartTime,
    this.breakStartTime,
    this.countdownStartTime,
    this.originalBreakSeconds = 0,
    this.shouldAnimateBlockedTime = false,
    this.isScheduleActive = false,
    this.isSchedulePaused = false,
    this.schedulePauseRemainingSeconds = 0,

    this.pomodoroConfig = const PomodoroConfig(),
    this.pomodoroRoundCount = 0,


  });



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
    String? activeSessionKey,
    Duration? todayBlockedTime,
    int? xpEarned,
    int? totalXp,
    DateTime? sessionStartTime,
    DateTime? breakStartTime,
    DateTime? countdownStartTime,
    int? originalBreakSeconds,
    bool? shouldAnimateBlockedTime,
    bool? isScheduleActive,
    bool? isSchedulePaused,
    int? schedulePauseRemainingSeconds,
    PomodoroConfig? pomodoroConfig,
    int? pomodoroRoundCount,

  }) {
    return HomeState(
      trackedApps: trackedApps ?? this.trackedApps,
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
      activeSessionKey: activeSessionKey ?? this.activeSessionKey,
      todayBlockedTime: todayBlockedTime ?? this.todayBlockedTime,
      xpEarned: xpEarned ?? this.xpEarned,
      totalXp: totalXp ?? this.totalXp,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      breakStartTime: breakStartTime ?? this.breakStartTime,
      countdownStartTime: countdownStartTime ?? this.countdownStartTime,
      originalBreakSeconds: originalBreakSeconds ?? this.originalBreakSeconds,
      shouldAnimateBlockedTime: shouldAnimateBlockedTime ?? this.shouldAnimateBlockedTime,
      isScheduleActive: isScheduleActive ?? this.isScheduleActive,
      isSchedulePaused: isSchedulePaused ?? this.isSchedulePaused,
      schedulePauseRemainingSeconds: schedulePauseRemainingSeconds ?? this.schedulePauseRemainingSeconds,
      pomodoroConfig: pomodoroConfig ?? this.pomodoroConfig,
      pomodoroRoundCount: pomodoroRoundCount ?? this.pomodoroRoundCount,


    );
  }


  // formatted for display HH:MM:SS
  String get formattedBlockedTime {
    final h = todayBlockedTime.inHours
        .toString().padLeft(2, '0');
    final m = (todayBlockedTime.inMinutes % 60)
        .toString().padLeft(2, '0');
    final s = (todayBlockedTime.inSeconds % 60)
        .toString().padLeft(2, '0');
    return '$h:$m:$s';
  }



  String get formattedPauseRemaining {
    final s = schedulePauseRemainingSeconds;
    final minutes = s ~/ 60;
    final seconds = s % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}