import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:screenblock/data/repositoryImpl/UsageStreakRepo.dart';
import '../../../domain/platform/blocking_service.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/blocking_service_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/timer_config.dart';
import '../../data/repositories/BlockingRepo.dart';
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

  @override
  HomeState build() {
    // only cleanup logic lives here
    ref.onDispose(() {
      _usageSubscription?.cancel();
      _overlaySubscription?.cancel();
      _countdownTimer?.cancel();
      _sessionTimer?.cancel();
      _breakTimer?.cancel();
      _streamsInitialized = false;

    });
    return const HomeState(isLoading: true);
  }

  // ── Called once from HomeScreen.initState ────────
  void init() {
    _setupStreams();
    loadTrackedApps();
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

    // start 3 second countdown
    state = state.copyWith(
      phase: BlockingPhase.countdown,
      remainingSeconds: 3,
    );

    _countdownTimer?.cancel();
    int count = 3;

    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) async {
        count--;
        if (count <= 0) {
          timer.cancel();
          await _beginActiveBlocking();
        } else {
          state = state.copyWith(remainingSeconds: count);
        }
      },
    );
  }

  Future<void> _beginActiveBlocking() async {
    // set blocking mode first
    _blockingService.setBlockingMode(state.blockingType);

    final apps = state.blockingType ==
        AppConstants.blockingTypeSpecificApps
        ? state.blockedApps
        : state.allowedApps;

    // start monitoring all selected apps
    for (final pkg in apps) {
      await _blockingService.startMonitoring(
        pkg,
        state.selectedMinutes,
      );
    }

    final totalSeconds = state.selectedMinutes * 60;

    state = state.copyWith(
      phase: BlockingPhase.active,
      remainingSeconds: totalSeconds,
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
  void _onSessionComplete() {
    _blockingService.stopAllMonitoring();
    state = state.copyWith(
      phase: BlockingPhase.idle,
      remainingSeconds: 0,
    );
  }



  // Block Modes

  void setBlockingType(String type) {
    state = state.copyWith(blockingType: type);
  }

  void setBlockedApps(List<String> apps) {
    state = state.copyWith(blockedApps: apps);
  }

  void setAllowedApps(List<String> apps) {
    state = state.copyWith(allowedApps: apps);
  }

  void setSelectedMinutes(int minutes) {
    state = state.copyWith(selectedMinutes: minutes);
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
    state = state.copyWith(
      phase: BlockingPhase.idle,
      remainingSeconds: 0,
      breakRemainingSeconds: 0,
    );
  }

  // ── Take a break ─────────────────────────────────
  Future<void> startBreak(int minutes) async {
    _sessionTimer?.cancel();
    await _blockingService.stopAllMonitoring();

    final breakSeconds = minutes * 60;
    state = state.copyWith(
      phase: BlockingPhase.onBreak,
      breakRemainingSeconds: breakSeconds,
    );

    _breakTimer?.cancel();
    _breakTimer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        final remaining = state.breakRemainingSeconds - 1;
        if (remaining <= 0) {
          timer.cancel();
          _resumeAfterBreak();
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
    await _beginActiveBlocking();
  }

  Future<void> _resumeAfterBreak() async {
    await _beginActiveBlocking();
  }



  // ── Getters ──────────────────────────────────────
  BlockingRepository get _blockingRepo =>
      ref.read(blockingRepositoryProvider);

  UsageStreakRepo get _usageRepo =>
      ref.read(usageRepositoryProvider);

  BlockingService get _blockingService =>
      ref.read(blockingServiceProvider);

  static const _methodChannel = MethodChannel(
    'com.example.screenblock/block',
  );

  void clearError() {
    state = state.copyWith(error: null);
  }
}

