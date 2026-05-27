import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:screenblock/data/repositoryImpl/UsageStreakRepo.dart';
import '../../../domain/platform/blocking_service.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/blocking_service_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/hivebox_names.dart';
import '../../data/models/timer_config.dart';
import '../../data/repositories/BlockingRepo.dart';
import '../../data/repositoryImpl/block_session_repository.dart';
import 'home_state.dart';

part 'home_viewmodel.g.dart';


@riverpod
class HomeViewModel extends _$HomeViewModel {

  StreamSubscription? _usageSubscription;
  StreamSubscription? _overlaySubscription;
  bool _streamsInitialized = false;
  Timer? _countdownTimer;
  Timer? _sessionTimer;
  Timer? _breakTimer;
  bool _initialized = false;

  static String _defaultBlockingType() =>
      Platform.isIOS
          ? AppConstants.blockingTypeSpecificApps
          : AppConstants.blockingTypeAllApps;

  @override
  HomeState build() {
    ref.keepAlive();
    // only cleanup logic lives here
    ref.onDispose(() {
      _initialized = false;
      _usageSubscription?.cancel();
      _overlaySubscription?.cancel();
      _countdownTimer?.cancel();
      _sessionTimer?.cancel();
      _breakTimer?.cancel();
      _streamsInitialized = false;

    });
    return HomeState(
      isLoading: true,
      blockingType: Platform.isIOS
          ? AppConstants.blockingTypeSpecificApps
          : AppConstants.blockingTypeAllApps,
    );
  }

  // ── Called once from HomeScreen.initState ────────
  void init() {
    if (_initialized) return;
    _initialized = true;

    _setupStreams();
    loadTrackedApps();
    loadTodayBlockedTime();
    _loadBlockingConfig();

    // load saved XP
    final savedXp = _loadTotalXp();
    state = state.copyWith(totalXp: savedXp);
  }

  int _loadTotalXp() {
    final box = Hive.box(HiveBoxNames.settings);
    return box.get('totalXp', defaultValue: 0) as int;
  }

  Future<void> _saveTotalXp(int xp) async {
    final box = Hive.box(HiveBoxNames.settings);
    await box.put('totalXp', xp);
  }

  Future<void> claimXp() async {
    final newTotal = state.totalXp + state.xpEarned;
    await _saveTotalXp(newTotal);

    state = state.copyWith(
      phase: BlockingPhase.idle,
      totalXp: newTotal,
      xpEarned: 0,
      remainingSeconds: 0,
      shouldAnimateBlockedTime: true,
    );
  }

  void resetAnimateBlockedTime() {
    state = state.copyWith(shouldAnimateBlockedTime: false);
  }



  void loadTodayBlockedTime() {
    final duration = _sessionRepo.getTodayTotalDuration();
    state = state.copyWith(todayBlockedTime: duration);
  }
  // ── Stream setup ─────────────────────────────────
  void _setupStreams() {
    if (_streamsInitialized) return;
    _streamsInitialized = true;

    // cancel any existing before creating new
    _usageSubscription?.cancel();
    _overlaySubscription?.cancel();

    _usageSubscription = _blockingService.usageEvents.listen(
            (event) {
      switch (event.type) {
        case AppEventType.timerExpired:
          state = state.copyWith(
            error: 'timer_expired:${event.packageName}',
          );
          // show overlay from main isolate
          _blockingService.blockApp(event.packageName);
          break;
        case AppEventType.appBlocked:
        // write to Hive so app stays blocked all day
          ref.read(blockingRepositoryProvider)
              .blockApp(event.packageName);
          state = state.copyWith(
            error: 'app_blocked:${event.packageName}',
          );
          break;
        case AppEventType.timerWarning:
          state = state.copyWith(
            error: 'timer_warning:${event.packageName}',
          );
          break;
        default:
          break;
      }
    });
    // overlay listener is a single-subscription stream
    // only subscribe if not already subscribed
    if (_overlaySubscription == null) {
      try {
        _overlaySubscription =
            FlutterOverlayWindow.overlayListener.listen((data) {
              if (data == 'block_for_day') {
                // TODO: block the app
              }
            });
      } catch (e) {
        debugPrint('❌ overlay listener already subscribed: $e');
      }
    }
    _methodChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onBlockDismissed':
          _blockingService.resetOverlayState();
          break;
      }
    });
  }

  // ── Load ─────────────────────────────────────────
  void loadTrackedApps() {
    try {
      final timers = _blockingRepo.getAllTimers();
      final streak = _usageRepo.getStreak();
      state = state.copyWith(
        trackedApps: timers,
        streak: streak,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // ── Add / remove ─────────────────────────────────
  Future<void> addTrackedApp(TimerConfig config) async {
    try {
      if (_blockingRepo.hasReachedFreeLimit()) {
        state = state.copyWith(error: 'free_limit_reached');
        return;
      }
      await _blockingRepo.saveTimer(config);
      await _blockingService.startMonitoring(
        config.packageName,
        config.limitMinutes,
      );
      loadTrackedApps();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> removeTrackedApp(String packageName) async {
    try {
      await _blockingRepo.deleteTimer(packageName);
      await _blockingService.stopMonitoring(packageName);
      loadTrackedApps();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ── Block / unblock ──────────────────────────────
  Future<void> blockAppForDay(String packageName) async {
    try {
      await _blockingRepo.blockApp(packageName);
      await _blockingService.blockApp(packageName);
      loadTrackedApps();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> unblockApp(String packageName) async {
    try {
      await _blockingRepo.unblockApp(packageName);
      await _blockingService.unblockApp(packageName);
      loadTrackedApps();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ── Start blocking ───────────────────────────────
  Future<void> startBlocking() async {
    final hasAccessibility =
    await _blockingService.hasAccessibilityPermission();
    if (!hasAccessibility) {
      await _blockingService.requestAccessibilityPermission();
      return;
    }

    final hasOverlay =
    await _blockingService.hasOverlayPermission();
    if (!hasOverlay) {
      await _blockingService.requestOverlayPermission();
      return;
    }

    final countdownStart = DateTime.now();

    // start 3 second countdown
    state = state.copyWith(
      phase: BlockingPhase.countdown,
      remainingSeconds: 3,
      countdownStartTime: countdownStart,
    );

    _countdownTimer?.cancel();
    int count = 3;

    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) async {
        final elapsed = DateTime.now()
            .difference(state.countdownStartTime!)
            .inSeconds;
        final remaining = 3 - elapsed;

        if (remaining <= 0) {
          timer.cancel();
          await _beginActiveBlocking();
        } else {
          state = state.copyWith(remainingSeconds: remaining);
        }
      },
    );
  }

  Future<void> _beginActiveBlocking() async {
    _blockingService.setBlockingMode(state.blockingType);

    if (Platform.isIOS) {
      await _blockingService.startMonitoring(
        'ios_apps',
        state.selectedMinutes,
      );
    } else {
      final apps = state.blockingType ==
          AppConstants.blockingTypeSpecificApps
          ? state.blockedApps
          : state.allowedApps;

      if (apps.isEmpty) {
        state = state.copyWith(
          phase: BlockingPhase.idle,
          error: 'no_apps_selected',
        );
        return;
      }

      for (final pkg in apps) {
        await _blockingService.startMonitoring(
          pkg,
          state.selectedMinutes,
        );
      }
    }

    final sessionKey = await _sessionRepo.startSession(
      blockingType: state.blockingType,
      selectedMinutes: state.selectedMinutes,
    );

    final totalSeconds = state.selectedMinutes * 60; // math that converts int into seconds
    final startTime = DateTime.now(); // 👈 wall clock start

    state = state.copyWith(
      phase: BlockingPhase.active,
      remainingSeconds: totalSeconds,
      activeSessionKey: sessionKey,
      sessionStartTime: startTime, // 👈 save start time
    );

    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        // calculate remaining from wall clock not tick count
        final elapsed = DateTime.now()
            .difference(state.sessionStartTime!)
            .inSeconds;
        final remaining = totalSeconds - elapsed;

        if (remaining <= 0) {
          timer.cancel();
          _onSessionComplete();
        } else {
          state = state.copyWith(remainingSeconds: remaining);
        }
      },
    );
  }

  void onAppResumed() {
    switch (state.phase) {
      case BlockingPhase.active:
        if (state.sessionStartTime == null) return;
        final totalSeconds = state.selectedMinutes * 60;
        final elapsed = DateTime.now()
            .difference(state.sessionStartTime!)
            .inSeconds;
        final remaining = totalSeconds - elapsed;
        if (remaining <= 0) {
          _sessionTimer?.cancel();
          _onSessionComplete();
        } else {
          state = state.copyWith(remainingSeconds: remaining);
        }

      case BlockingPhase.onBreak:
        if (state.breakStartTime == null) return;
        final breakElapsed = DateTime.now()
            .difference(state.breakStartTime!)
            .inSeconds;
        final breakRemaining = state.originalBreakSeconds - breakElapsed;
        if (breakRemaining <= 0) {
          _breakTimer?.cancel();
          _resumeAfterBreak(state.remainingSeconds);
        } else {
          state = state.copyWith(breakRemainingSeconds: breakRemaining);
        }

      case BlockingPhase.countdown:
        if (state.countdownStartTime == null) return;
        final countdownElapsed = DateTime.now()
            .difference(state.countdownStartTime!)
            .inSeconds;
        final countdownRemaining = 3 - countdownElapsed;
        if (countdownRemaining <= 0) {
          _countdownTimer?.cancel();
          _beginActiveBlocking();
        } else {
          state = state.copyWith(remainingSeconds: countdownRemaining);
        }

      default:
        break;
    }
  }

  void finishAndUnblock() {
    state = state.copyWith(
      phase: BlockingPhase.claimXp,
    );
  }



  void _onSessionComplete() async {
    _blockingService.stopAllMonitoring();

    // end session in Hive as completed
    if (state.activeSessionKey != null) {
      await _sessionRepo.endSession(
        key: state.activeSessionKey!,
        completed: true, // timer expired naturally
      );
    }

    await Future.delayed(const Duration(milliseconds: 100));
    // refresh today's total
    loadTodayBlockedTime();

    // calculate XP — 1 XP per minute blocked
    final xpEarned = state.selectedMinutes;


    state = state.copyWith(
      phase: BlockingPhase.completed,
      remainingSeconds: 0,
      activeSessionKey: null,
      xpEarned : xpEarned,
    );
  }



  // Block Modes
  void _saveBlockingConfig() {
    final box = Hive.box(HiveBoxNames.settings);
    box.put('blockingType', state.blockingType);
    box.put('blockedApps', state.blockedApps);
    box.put('allowedApps', state.allowedApps);
  }

  void setBlockingType(String type) {
    state = state.copyWith(blockingType: type);
    _saveBlockingConfig();

  }

  void setBlockedApps(List<String> apps) {
    state = state.copyWith(blockedApps: apps);
    // persist to Hive
    _saveBlockingConfig();
  }

  void setAllowedApps(List<String> apps) {
    state = state.copyWith(allowedApps: apps);
    _saveBlockingConfig();

  }

  void setSelectedMinutes(int minutes) {
    state = state.copyWith(selectedMinutes: minutes);
  }

  void _loadBlockingConfig() {
    final box = Hive.box(HiveBoxNames.settings);
    final blockingType = box.get('blockingType',
        defaultValue: Platform.isIOS
            ? AppConstants.blockingTypeSpecificApps
            : AppConstants.blockingTypeAllApps);
    final blockedApps = box.get('blockedApps',
        defaultValue: <String>[]);
    final allowedApps = box.get('allowedApps',
        defaultValue: <String>[]);

    state = state.copyWith(
      blockingType: blockingType,
      blockedApps: List<String>.from(blockedApps),
      allowedApps: List<String>.from(allowedApps),
    );
  }


  // ── Cancel countdown ─────────────────────────────
  void cancelCountdown() {
    _countdownTimer?.cancel();
    state = state.copyWith(
      phase: BlockingPhase.idle,
      remainingSeconds: 0,
    );
  }

  // ── Give up ──────────────────────────────────────
  Future<void> giveUp() async {
    _sessionTimer?.cancel();
    _breakTimer?.cancel();
    await _blockingService.stopAllMonitoring();

    // end session in Hive
    if (state.activeSessionKey != null) {
      await _sessionRepo.endSession(
        key: state.activeSessionKey!,
        completed: false, // gave up
      );
    }

    // 👇 small delay to ensure Hive write is complete
    await Future.delayed(const Duration(milliseconds: 100));
    // refresh today's total
    loadTodayBlockedTime();

    state = state.copyWith(
      phase: BlockingPhase.idle,
      remainingSeconds: 0,
      breakRemainingSeconds: 0,
      activeSessionKey: null,
    );
  }

  // ── Take a break ─────────────────────────────────
  Future<void> startBreak(int minutes) async {
    _sessionTimer?.cancel();
    await _blockingService.stopAllMonitoring();

    final breakSeconds = minutes * 60;
    // 👇 save current remaining seconds before break
    final breakStartTime = DateTime.now();

    state = state.copyWith(
      phase: BlockingPhase.onBreak,
      breakRemainingSeconds: breakSeconds,
      breakStartTime: breakStartTime,
      originalBreakSeconds: breakSeconds
    );

    _breakTimer?.cancel();
    _breakTimer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        final elapsed = DateTime.now()
            .difference(state.breakStartTime!)
            .inSeconds;
        final remaining = breakSeconds - elapsed;

        if (remaining <= 0) {
          timer.cancel();
          _resumeAfterBreak(state.remainingSeconds);
        } else {
          state = state.copyWith(
            breakRemainingSeconds: remaining,
          );
        }
      },
    );
  }

  Future<void> endBreak() async {
    _breakTimer?.cancel();
    _resumeAfterBreak(state.remainingSeconds);
  }

  Future<void> _resumeAfterBreak(int remainingSeconds) async {
    _blockingService.setBlockingMode(state.blockingType);

    final apps = state.blockingType ==
        AppConstants.blockingTypeSpecificApps
        ? state.blockedApps
        : state.allowedApps;

    if (Platform.isIOS) {
      await _blockingService.startMonitoring(
        'ios_apps',
        state.selectedMinutes,
      );
    } else {
      for (final pkg in apps) {
        await _blockingService.startMonitoring(
          pkg,
          state.selectedMinutes,
        );
      }
    }

    // 👇 resume from saved remaining seconds, not full duration
    state = state.copyWith(
      phase: BlockingPhase.active,
      remainingSeconds: remainingSeconds,
    );

    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        final remaining = state.remainingSeconds - 1;
        if (remaining <= 0) {
          timer.cancel();
          _onSessionComplete();
        } else {
          state = state.copyWith(remainingSeconds: remaining);
        }
      },
    );
  }


  // ── Getters ──────────────────────────────────────
  BlockingRepository get _blockingRepo =>
      ref.read(blockingRepositoryProvider);

  BlockSessionRepository get _sessionRepo =>
      ref.read(blockSessionRepositoryProvider);

  UsageStreakRepo get _usageRepo =>
      ref.read(usageRepositoryProvider);

  BlockingService get _blockingService =>
      ref.read(blockingServiceProvider);

  static const _methodChannel = MethodChannel(
    'com.eagle.screenblock/block',
  );

  void clearError() {
    state = state.copyWith(error: null);
  }
}

