import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:hive/hive.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:just_audio/just_audio.dart';
import 'package:pausenow/features/home/timer/pomodoro_sheet.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pausenow/data/repositoryImpl/UsageStreakRepo.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/platform/blocking_service.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/blocking_service_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/hivebox_names.dart';
import '../../data/models/schedule.dart';
import '../../data/repositories/BlockingRepo.dart';
import '../../data/repositoryImpl/block_session_repository.dart';
import '../../domain/platform/android_blocking_service.dart';
import '../../domain/platform/ios_blocking_service.dart';
import '../../providers/premium_provider.dart';
import '../../services/notification_service.dart';
import '../../services/schedule_checker.dart';
import '../appPicker/app_picker_viewmodel.dart';
import 'home_state.dart';

part 'home_viewmodel.g.dart';

@riverpod
class HomeViewModel extends _$HomeViewModel {

  // ── Private fields ───────────────────────────────
  StreamSubscription? _usageSubscription;
  StreamSubscription? _overlaySubscription;
  bool _streamsInitialized = false;
  Timer? _countdownTimer;
  Timer? _sessionTimer;
  Timer? _breakTimer;
  bool _initialized = false;

  // ── Build ────────────────────────────────────────
  @override
  HomeState build() {
    ref.keepAlive();
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
      blockingType: AppConstants.blockingTypeSpecificApps,
    );
  }

  // ── Init ─────────────────────────────────────────
  void init() {
    if (_initialized) return;
    _initialized = true;

    // listen for native pause ended event — iOS only
    if (Platform.isIOS) {
      IOSBlockingService.listenForNativeEvents(
        onPauseEnded: () {
          debugPrint('📱 native pause ended');
          if (state.phase == BlockingPhase.onBreak) {
            _resumeAfterBreak(state.remainingSeconds);
          }
        },
        onSessionComplete: () {
          debugPrint('📱 native session complete');
          if (state.phase == BlockingPhase.active) {
            _onSessionComplete();
          }
        },
        onNotificationStartBreak: () { // 👈 add
          debugPrint('🔔 user tapped Start Break from notification');
          if (state.phase == BlockingPhase.active) {
            _onPomodoroRoundComplete();
          }
        },
        onNotificationStartWork: () { // 👈 add
          debugPrint('🔔 user tapped Start Working from notification');
          if (state.phase == BlockingPhase.onBreak) {
            _resumeAfterPomodoroBreak();
          }
        },
        onNotificationExtendBreak: () { // 👈 add
          debugPrint('🔔 user tapped Extend Break from notification');
          if (state.phase == BlockingPhase.onBreak) {
            // add 5 more minutes to current break
            startBreak(5);
          }
        },
      );
    }

    _setupStreams();
    loadTrackedApps();
    loadTodayBlockedTime();
    _loadBlockingConfig();

    final savedXp = _loadTotalXp();
    state = state.copyWith(totalXp: savedXp);

    // pre-load Android app list in background
    if (Platform.isAndroid) {
      Future.microtask(() {
        ref.read(appPickerViewModelProvider.notifier).loadApps();
      });
    }

    _setupScheduleChecker();
    _setupPremiumListener();

    ScheduleChecker.instance.start(_blockingService);
    _restoreSession();

    _requestReviewAfterDays();

  }

  Future<void> _requestReviewAfterDays() async {
    final box = Hive.box(HiveBoxNames.settings);

    final installDateMs = box.get('installDate') as int?;
    if (installDateMs == null) return;

    final installDate = DateTime.fromMillisecondsSinceEpoch(installDateMs);
    final daysSinceInstall = DateTime.now().difference(installDate).inDays;

    // 👇 day 3 trigger
    final hasRequestedDay3 = box.get('hasRequestedReviewDay3', defaultValue: false) as bool;
    if (!hasRequestedDay3 && daysSinceInstall >= 3) {
      await box.put('hasRequestedReviewDay3', true);
      await _showReviewPrompt();
      return; // 👈 don't fire two prompts in one launch
    }

    // 👇 day 7 trigger — only if day 3 already happened
    final hasRequestedDay7 = box.get('hasRequestedReviewDay7', defaultValue: false) as bool;
    if (hasRequestedDay3 && !hasRequestedDay7 && daysSinceInstall >= 7) {
      await box.put('hasRequestedReviewDay7', true);
      await _showReviewPrompt();
    }
  }

  Future<void> requestReviewOnFirstClaim() async {
    final box = Hive.box(HiveBoxNames.settings);
    final hasRequestedOnFirstClaim = box.get('hasRequestedReviewFirstClaim', defaultValue: false) as bool;
    if (hasRequestedOnFirstClaim) return;

    await box.put('hasRequestedReviewFirstClaim', true);
    await _showReviewPrompt();
  }

  void _setupScheduleChecker() {
    final checker = ScheduleChecker.instance;

    checker.onScheduleStarted = () {
      state = state.copyWith(isScheduleActive: true);
    };
    checker.onScheduleStopped = () {
      state = state.copyWith(
        isScheduleActive: false,
        isSchedulePaused: false,
        schedulePauseRemainingSeconds: 0,
      );
    };
    checker.onSchedulePaused = () {
      state = state.copyWith(
        isScheduleActive: true,
        isSchedulePaused: true,
      );
    };
    checker.onScheduleResumed = () {
      state = state.copyWith(
        isSchedulePaused: false,
        schedulePauseRemainingSeconds: 0,
      );
    };
    checker.onPauseTickChanged = (remaining) {
      state = state.copyWith(schedulePauseRemainingSeconds: remaining);
    };
    checker.isPremium = () => ref.read(isPremiumProvider);
    checker.isManualBlocking = () =>
    state.phase == BlockingPhase.active ||
        state.phase == BlockingPhase.onBreak ||
        state.phase == BlockingPhase.countdown;
  }

  void _setupPremiumListener() {
    ref.listen(isPremiumProvider, (previous, next) {
      if (previous == true && next == false) {
        _onPremiumLost();
      }
    });
  }

  // ── Premium Logic───────────────────────────────────────

  void _onPremiumLost() {
    debugPrint('💎 Premium lost — enforcing free tier');

    // 👇 capture before state changes
    final wasAllApps = state.blockingType == AppConstants.blockingTypeAllApps;

    // 👇 stop pomodoro session if active
    if (state.pomodoroConfig.isPomodoroMode &&
        (state.phase == BlockingPhase.active || state.phase == BlockingPhase.onBreak)) {
      giveUp();
    }

    // reset blocking type
    if (wasAllApps) {
      setBlockingType(AppConstants.blockingTypeSpecificApps);
      debugPrint('💎 blocking type reset to specific apps');
    }

    if (state.pomodoroConfig.isPomodoroMode) {
      state = state.copyWith(
        pomodoroConfig: state.pomodoroConfig.copyWith(isPomodoroMode: false),
      );
      debugPrint('💎 pomodoro mode disabled');
    }

    // 👇 update any saved schedules that use all_apps blocking type
    final scheduleBox = Hive.box<Schedule>(HiveBoxNames.schedules);
    for (final key in scheduleBox.keys) {
      final schedule = scheduleBox.get(key);
      if (schedule != null &&
          schedule.blockingType == AppConstants.blockingTypeAllApps) {
        final updated = schedule.copyWith(
          blockingType: AppConstants.blockingTypeSpecificApps,
        );
        scheduleBox.put(key, updated);
      }
    }

    if (state.isScheduleActive) {
      final isPremium = ref.read(isPremiumProvider);
      ScheduleChecker.instance.isPremium = () => isPremium;
      ScheduleChecker.instance.checkNow();
    }

    // end session if was blocking all apps
    if (state.phase == BlockingPhase.active && wasAllApps) {
      giveUp();
    }
  }

  // Pro
  void setPomodoroConfig(PomodoroConfig config) {
    state = state.copyWith(pomodoroConfig: config);
    if (config.isPomodoroMode) {
      state = state.copyWith(selectedMinutes: config.workMinutes);
    }
  }

  // ── XP ───────────────────────────────────────────
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


    await NotificationService.instance.cancelNotification(202);


    state = state.copyWith(
      phase: BlockingPhase.idle,
      totalXp: newTotal,
      xpEarned: 0,
      remainingSeconds: 0,
      shouldAnimateBlockedTime: true,
    );
  }




  Future<void> _showReviewPrompt() async {
    try {
      final inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        debugPrint('⭐️ review requested');
      }
    } catch (e) {
      debugPrint('❌ review error: $e');
    }
  }

  void resetAnimateBlockedTime() {
    state = state.copyWith(shouldAnimateBlockedTime: false);
  }

  // ── Schedule ──────────────────────────────────────
  void pauseSchedule(int minutes) {
    ScheduleChecker.instance.pauseFor(minutes);
  }

  void resumeSchedule() {
    ScheduleChecker.instance.resumeNow();
  }

  // ── Today blocked time ────────────────────────────
  void loadTodayBlockedTime() {
    final duration = _sessionRepo.getTodayTotalDuration();
    state = state.copyWith(todayBlockedTime: duration);
  }

  // ── Streams ───────────────────────────────────────
  void _setupStreams() {
    if (_streamsInitialized) return;
    _streamsInitialized = true;

    _usageSubscription?.cancel();
    _overlaySubscription?.cancel();

    _usageSubscription = _blockingService.usageEvents.listen((event) {
      switch (event.type) {
        case AppEventType.timerExpired:
          state = state.copyWith(error: 'timer_expired:${event.packageName}');
          _blockingService.blockApp(event.packageName);
          break;
        case AppEventType.appBlocked:
          ref.read(blockingRepositoryProvider).blockApp(event.packageName);
          state = state.copyWith(error: 'app_blocked:${event.packageName}');
          break;
        case AppEventType.timerWarning:
          state = state.copyWith(error: 'timer_warning:${event.packageName}');
          break;
        case AppEventType.scheduleResumed:
          debugPrint('📅 Schedule resume event received from Kotlin');
          ScheduleChecker.instance.resumeNow();
          break;
        default:
          break;
      }
    });

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

  // ── Load ──────────────────────────────────────────
  void loadTrackedApps() {
    try {
      final timers = _blockingRepo.getAllTimers();
      state = state.copyWith(
        trackedApps: timers,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Blocking config ───────────────────────────────
  void _saveBlockingConfig() {
    final box = Hive.box(HiveBoxNames.settings);
    box.put('blockingType', state.blockingType);
    box.put('blockedApps', state.blockedApps);
    box.put('allowedApps', state.allowedApps);
  }

  void _loadBlockingConfig() {
    final box = Hive.box(HiveBoxNames.settings);
    state = state.copyWith(
      blockingType: box.get('blockingType',
          defaultValue: AppConstants.blockingTypeSpecificApps),
      blockedApps: List<String>.from(
          box.get('blockedApps', defaultValue: <String>[])),
      allowedApps: List<String>.from(
          box.get('allowedApps', defaultValue: <String>[])),
    );
  }

  void setBlockingType(String type) {
    state = state.copyWith(blockingType: type);
    _saveBlockingConfig();
  }

  void setBlockedApps(List<String> apps) {
    state = state.copyWith(blockedApps: apps);
    _saveBlockingConfig();
  }

  void setAllowedApps(List<String> apps) {
    state = state.copyWith(allowedApps: apps);
    _saveBlockingConfig();
  }

  void setSelectedMinutes(int minutes) {
    state = state.copyWith(selectedMinutes: minutes);
  }

  // ── Start blocking ────────────────────────────────
  Future<void> startBlocking() async {

    final countdownStart = DateTime.now();
    state = state.copyWith(
      phase: BlockingPhase.countdown,
      remainingSeconds: 3,
      countdownStartTime: countdownStart,
    );

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
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
    });
  }

  Future<void> _beginActiveBlocking() async {
    _blockingService.setBlockingMode(state.blockingType);

    // 👇 schedule session complete notification at start
    if (!state.pomodoroConfig.isPomodoroMode) {
      await NotificationService.instance.cancelNotification(202);
      await NotificationService.instance.scheduleNotification(
        id: 202,
        title: 'Session Complete! ⚡',
        body: 'Tap to claim your ⭐️ stars.',
        scheduledTime: DateTime.now().add(
          Duration(minutes: state.selectedMinutes),
        ),
      );
    }

    if (Platform.isIOS) {
      final hasApps = state.blockingType == AppConstants.blockingTypeSpecificApps
          ? state.blockedApps.isNotEmpty
          : state.allowedApps.isNotEmpty;

      if (!hasApps) {
        state = state.copyWith(phase: BlockingPhase.idle, error: 'no_apps_selected');
        return;
      }

      final iosService = _blockingService as IOSBlockingService;
      await iosService.startMonitoring(
        'ios_apps',
        state.selectedMinutes,
        'manual',
        state.blockingType,
      );
    } else {
      final apps = state.blockingType == AppConstants.blockingTypeSpecificApps
          ? state.blockedApps
          : state.allowedApps;

      if (apps.isEmpty) {
        state = state.copyWith(phase: BlockingPhase.idle, error: 'no_apps_selected');
        return;
      }

      for (final pkg in apps) {
        await _blockingService.startMonitoring(pkg, state.selectedMinutes);
      }

      if (_blockingService is AndroidBlockingService) {
        await (_blockingService as AndroidBlockingService).persistBlockingState(
          sessionMinutes: state.selectedMinutes,
        );
      }
    }

    final sessionKey = await _sessionRepo.startSession(
      blockingType: state.blockingType,
      selectedMinutes: state.selectedMinutes,
    );

    final totalSeconds = state.selectedMinutes * 60;
    final startTime = DateTime.now();

    state = state.copyWith(
      phase: BlockingPhase.active,
      remainingSeconds: totalSeconds,
      activeSessionKey: sessionKey,
      sessionStartTime: startTime,
    );

    // 👇 schedule break notification if pomodoro mode
    if (state.pomodoroConfig.isPomodoroMode) {
      await NotificationService.instance.cancelNotification(200);
      await NotificationService.instance.scheduleNotification(
        id: 200,
        title: 'Break time! 🍅',
        body: 'Hold For Options',
        scheduledTime: DateTime.now().add(
          Duration(minutes: state.pomodoroConfig.workMinutes),
        ),
        categoryIdentifier: 'POMODORO_WORK_ENDED', // 👈 add actions
      );
    }


    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final elapsed = DateTime.now().difference(state.sessionStartTime!).inSeconds;
      final remaining = totalSeconds - elapsed;
      if (remaining <= 0) {
        timer.cancel();
        _onSessionComplete();
      } else {
        state = state.copyWith(remainingSeconds: remaining);
      }
    });
  }

  // ── Session complete ──────────────────────────────
  void _onSessionComplete() async {
    if (state.phase != BlockingPhase.active) {
      debugPrint('⚠️ _onSessionComplete ignored — phase is ${state.phase}');
      return;
    }


    if (state.pomodoroConfig.isPomodoroMode) {
      _onPomodoroRoundComplete();
      return;
    }

    if (Platform.isIOS) {
      await (_blockingService as IOSBlockingService).stopBlockingCompletely();
    } else {
      _blockingService.stopAllMonitoring();
    }

    // 👇 play completion sound
    if (Platform.isAndroid) {
      try {
        final player = AudioPlayer();
        await player.setAsset('assets/sounds/bell.wav');
        await player.setVolume(0.8);
        await player.play();
        await player.playerStateStream.firstWhere(
              (state) => state.processingState == ProcessingState.completed,
        );
        await player.dispose();
      } catch (e) {
        debugPrint('❌ sound error: $e');
      }
      HapticFeedback.heavyImpact();
    }

    if (state.activeSessionKey != null) {
      await _sessionRepo.endSession(
        key: state.activeSessionKey!,
        completed: true,
      );
    }

    await Future.delayed(const Duration(milliseconds: 100));
    loadTodayBlockedTime();

    state = state.copyWith(
      phase: BlockingPhase.completed,
      remainingSeconds: 0,
      activeSessionKey: null,
      xpEarned: state.selectedMinutes * 5,
    );

    ScheduleChecker.instance.checkNow();
  }

  // ── Pomodoro round complete ───────────────────────
  void _onPomodoroRoundComplete() async {
    if (state.activeSessionKey != null) {
      await _sessionRepo.endSession(
        key: state.activeSessionKey!,
        completed: true,
      );
    }

    final xpThisRound = state.pomodoroConfig.workMinutes * 5;
    final totalXpEarned = state.xpEarned + xpThisRound;
    final newRoundCount = state.pomodoroRoundCount + 1;

    state = state.copyWith(
      pomodoroRoundCount: newRoundCount,
      xpEarned: totalXpEarned,
    );

    final isLongBreak = newRoundCount % 4 == 0;
    final breakMinutes = isLongBreak
        ? state.pomodoroConfig.longBreakMinutes
        : state.pomodoroConfig.shortBreakMinutes;

    // 👇 save to shared defaults so onAppResumed knows break already started
    if (Platform.isIOS) {
      await const MethodChannel('com.eagle.pausenow/ios_blocking')
          .invokeMethod('savePomodoroBreakState', {
        'roundCount': newRoundCount,
        'breakMinutes': breakMinutes,
        'breakStartTime': DateTime.now().millisecondsSinceEpoch,
        'isLongBreak': isLongBreak,
      });
      await (_blockingService as IOSBlockingService).playSystemSound(1005);
    } else {
      // 👇 Android sound
      try {
        final player = AudioPlayer();
        await player.setAsset('assets/sounds/bell.wav');
        await player.setVolume(0.8);
        await player.play();
        await player.playerStateStream.firstWhere(
              (state) => state.processingState == ProcessingState.completed,
        );
        await player.dispose();
      } catch (e) {
        debugPrint('❌ sound error: $e');
      }
      HapticFeedback.heavyImpact();
    }

    await NotificationService.instance.cancelNotification(200);
    await NotificationService.instance.scheduleNotification(
      id: 201,
      title: 'Break over! 🔒',
      body: 'Hold For Options',
      scheduledTime: DateTime.now().add(Duration(minutes: breakMinutes)),
      categoryIdentifier: 'POMODORO_BREAK_ENDED',
    );
    await NotificationService.instance.scheduleNotification(
      id: 200,
      title: 'Break time! 🍅',
      body: isLongBreak
          ? 'Great work! Time for a long break — you earned it.'
          : 'Work session complete! Take a short break.',
      scheduledTime: DateTime.now().add(const Duration(seconds: 1)),
      categoryIdentifier: 'POMODORO_WORK_ENDED',
    );

    await Future.delayed(const Duration(milliseconds: 300));
    startBreak(breakMinutes);
  }

  void finishAndUnblock() {
    state = state.copyWith(phase: BlockingPhase.claimXp);
  }

  // ── Cancel countdown ──────────────────────────────
  void cancelCountdown() {
    _countdownTimer?.cancel();
    state = state.copyWith(phase: BlockingPhase.idle, remainingSeconds: 0);
  }

  // ── Give up ───────────────────────────────────────
  Future<void> giveUp() async {
    _sessionTimer?.cancel();
    _breakTimer?.cancel();

    await NotificationService.instance.cancelNotification(200);
    await NotificationService.instance.cancelNotification(201); // 👈 add
    await NotificationService.instance.cancelNotification(202);

    if (Platform.isIOS) {
      await (_blockingService as IOSBlockingService).stopBlockingCompletely();
    } else {
      await _blockingService.stopAllMonitoring();
    }

    if (state.activeSessionKey != null) {
      await _sessionRepo.endSession(
        key: state.activeSessionKey!,
        completed: false,
      );
    }

    await Future.delayed(const Duration(milliseconds: 100));
    loadTodayBlockedTime();

    // 👇 pomodoro with completed rounds → show claim screen
    // manual blocking or pomodoro with 0 rounds → go idle
    if (state.pomodoroConfig.isPomodoroMode && state.xpEarned > 0) {
      state = state.copyWith(
        phase: BlockingPhase.completed,
        remainingSeconds: 0,
        activeSessionKey: null,
        pomodoroRoundCount: 0,
      );
    } else {
      state = state.copyWith(
        phase: BlockingPhase.idle,
        remainingSeconds: 0,
        breakRemainingSeconds: 0,
        activeSessionKey: null,
        pomodoroRoundCount: 0,
        xpEarned: 0,
      );
    }

    ScheduleChecker.instance.checkNow();
  }

  // ── Break ─────────────────────────────────────────
  Future<void> startBreak(int minutes) async {
    _sessionTimer?.cancel();

    if (Platform.isIOS) {
      await (_blockingService as IOSBlockingService).pauseBlocking(minutes);
    } else {
      await _blockingService.stopAllMonitoring();
      final breakEndsAt = DateTime.now().add(Duration(minutes: minutes));
      await (_blockingService as AndroidBlockingService)
          .savePauseEndTime(breakEndsAt.millisecondsSinceEpoch);
    }

    final breakSeconds = minutes * 60;
    final breakStartTime = DateTime.now();

    state = state.copyWith(
      phase: BlockingPhase.onBreak,
      breakRemainingSeconds: breakSeconds,
      breakStartTime: breakStartTime,
      originalBreakSeconds: breakSeconds,
    );

    _breakTimer?.cancel();
    _breakTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final elapsed = DateTime.now().difference(state.breakStartTime!).inSeconds;
      final remaining = breakSeconds - elapsed;
      if (remaining <= 0) {
        timer.cancel();
        _resumeAfterBreak(state.remainingSeconds);
      } else {
        state = state.copyWith(breakRemainingSeconds: remaining);
      }
    });
  }

  Future<void> endBreak() async {
    _breakTimer?.cancel();
    if (Platform.isAndroid && _blockingService is AndroidBlockingService) {
      await (_blockingService as AndroidBlockingService).savePauseEndTime(0);
    }
    _resumeAfterBreak(state.remainingSeconds);
  }


// ── Resume after break ────────────────────────────
  Future<void> _resumeAfterBreak(int remainingSeconds) async {
    if (state.pomodoroConfig.isPomodoroMode) {
      await _resumeAfterPomodoroBreak();
      return;
    }

    _blockingService.setBlockingMode(state.blockingType);

    if (Platform.isIOS) {
      if (state.phase == BlockingPhase.onBreak) {
        await (_blockingService as IOSBlockingService).resumeBlocking();
      }
    } else {
      final apps = state.blockingType == AppConstants.blockingTypeSpecificApps
          ? state.blockedApps
          : state.allowedApps;
      for (final pkg in apps) {
        await _blockingService.startMonitoring(pkg, state.selectedMinutes);
      }
      if (_blockingService is AndroidBlockingService) {
        final svc = _blockingService as AndroidBlockingService;
        await svc.savePauseEndTime(0);
        await svc.persistBlockingState(
          sessionMinutes: state.selectedMinutes,
          sessionType: 'manual',
        );
        await svc.checkCurrentForegroundApp();
      }
    }

    state = state.copyWith(
      phase: BlockingPhase.active,
      remainingSeconds: remainingSeconds,
    );

    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final totalSeconds = state.selectedMinutes * 60;
      final elapsed = DateTime.now().difference(state.sessionStartTime!).inSeconds;
      final remaining = totalSeconds - elapsed;
      if (remaining <= 0) {
        timer.cancel();
        _onSessionComplete();
      } else {
        state = state.copyWith(remainingSeconds: remaining);
      }
    });
  }


  // ── Resume after Pomodoro break ───────────────────
  Future<void> _resumeAfterPomodoroBreak() async {
    _blockingService.setBlockingMode(state.blockingType);

    if (Platform.isIOS) {
      // 👇 all iOS stuff in one block
      await (_blockingService as IOSBlockingService).playSystemSound(1005);
      await const MethodChannel('com.eagle.pausenow/ios_blocking')
          .invokeMethod('clearPomodoroBreakState');
      final iosService = _blockingService as IOSBlockingService;
      await iosService.startMonitoring(
        'ios_apps',
        state.pomodoroConfig.workMinutes,
        'manual',
        state.blockingType,
      );
    } else {
      final apps = state.blockingType == AppConstants.blockingTypeSpecificApps
          ? state.blockedApps
          : state.allowedApps;
      for (final pkg in apps) {
        await _blockingService.startMonitoring(pkg, state.pomodoroConfig.workMinutes);
      }
      if (_blockingService is AndroidBlockingService) {
        final svc = _blockingService as AndroidBlockingService;
        await svc.savePauseEndTime(0);
        await svc.persistBlockingState(
          sessionMinutes: state.pomodoroConfig.workMinutes,
          sessionType: 'manual',
        );
        await svc.checkCurrentForegroundApp();
      }
    }

    final workMinutes = state.pomodoroConfig.workMinutes;
    final newStartTime = DateTime.now();
    final totalSeconds = workMinutes * 60;

    state = state.copyWith(
      phase: BlockingPhase.active,
      selectedMinutes: workMinutes,
      remainingSeconds: totalSeconds,
      sessionStartTime: newStartTime,
      breakRemainingSeconds: 0,
    );

    // 👇 reschedule break notification for next round
    await NotificationService.instance.cancelNotification(200);
    await NotificationService.instance.scheduleNotification(
      id: 200,
      title: 'Break time! 🍅',
      body: 'Work session complete! Take a short break.',
      scheduledTime: DateTime.now().add(Duration(minutes: workMinutes)),
      categoryIdentifier: 'POMODORO_WORK_ENDED',
    );

    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final elapsed = DateTime.now().difference(state.sessionStartTime!).inSeconds;
      final remaining = totalSeconds - elapsed;
      if (remaining <= 0) {
        timer.cancel();
        _onPomodoroRoundComplete();
      } else {
        state = state.copyWith(remainingSeconds: remaining);
      }
    });
  }

  // ── App resumed ───────────────────────────────────
  void onAppResumed() async {
    debugPrint('🔄 onAppResumed — phase: ${state.phase} isScheduleActive: ${state.isScheduleActive}');
    if (Platform.isIOS) {
      _checkPendingXpClaim();
    }
    if (state.isSchedulePaused) {
      final pauseEndTime = ScheduleChecker.instance.pauseEndsAt;
      if (pauseEndTime != null && DateTime.now().isAfter(pauseEndTime)) {
        debugPrint('📅 Pause expired while backgrounded — resuming');
        ScheduleChecker.instance.resumeNow();
      }
    }




    switch (state.phase) {
      case BlockingPhase.active:
        if (state.sessionStartTime == null) return;
        final totalSeconds = state.selectedMinutes * 60;
        final elapsed = DateTime.now().difference(state.sessionStartTime!).inSeconds;
        final remaining = totalSeconds - elapsed;
        if (remaining <= 0) {
          _sessionTimer?.cancel();

          // 👇 check if Pomodoro break already started natively
          if (Platform.isIOS && state.pomodoroConfig.isPomodoroMode) {
            final breakState = await const MethodChannel('com.eagle.pausenow/ios_blocking')
                .invokeMethod<Map>('getPomodoroBreakState');

            if (breakState != null && breakState['pomodoroPhase'] == 'break') {
              // break already started — sync state from native
              final breakMinutes = breakState['pomodoroBreakMinutes'] as int?
                  ?? state.pomodoroConfig.shortBreakMinutes;
              final breakStartMs = breakState['pomodoroBreakStartTime'] as int? ?? 0;
              final roundCount = breakState['pomodoroRoundCount'] as int?
                  ?? state.pomodoroRoundCount;
              final breakStartTime = DateTime.fromMillisecondsSinceEpoch(breakStartMs);
              final breakElapsed = DateTime.now().difference(breakStartTime).inSeconds;
              final breakRemaining = (breakMinutes * 60) - breakElapsed;

              debugPrint('🍅 break already started — round=$roundCount breakMinutes=$breakMinutes remaining=${breakRemaining}s');

              if (breakRemaining <= 0) {
                // break already ended — start next work
                state = state.copyWith(pomodoroRoundCount: roundCount);
                await _resumeAfterPomodoroBreak();
              } else {
                // sync to correct break state
                state = state.copyWith(
                  phase: BlockingPhase.onBreak,
                  pomodoroRoundCount: roundCount,
                  breakRemainingSeconds: breakRemaining,
                  originalBreakSeconds: breakMinutes * 60,
                  breakStartTime: breakStartTime,
                );
                _breakTimer?.cancel();
                _breakTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                  final elapsed = DateTime.now()
                      .difference(state.breakStartTime!)
                      .inSeconds;
                  final remaining = state.originalBreakSeconds - elapsed;
                  if (remaining <= 0) {
                    timer.cancel();
                    _resumeAfterBreak(state.remainingSeconds);
                  } else {
                    state = state.copyWith(breakRemainingSeconds: remaining);
                  }
                });
              }
              return;
            }
          }

          _onSessionComplete(); // 👈 only if no native break state found
        } else {
          state = state.copyWith(remainingSeconds: remaining);
        }

      case BlockingPhase.onBreak:
        if (state.breakStartTime == null) return;
        final breakElapsed = DateTime.now().difference(state.breakStartTime!).inSeconds;
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

  Future<void> _checkPendingXpClaim() async {
    try {
      final result = await const MethodChannel('com.eagle.pausenow/ios_blocking')
          .invokeMethod<bool>('checkAndClearPendingClaim');
      if (result == true && state.phase == BlockingPhase.completed) {
        debugPrint('⭐️ pending XP claim detected — showing claim screen');
        // state is already BlockingPhase.completed so claim screen shows automatically
      }
    } catch (e) {
      debugPrint('❌ checkPendingXpClaim error: $e');
    }
  }

  // ── Restore session ───────────────────────────────
  Future<void> _restoreSession() async {
    try {
      if (Platform.isIOS) {
        final result = await const MethodChannel('com.eagle.pausenow/ios_blocking')
            .invokeMethod<Map>('getPersistedSession')
            .timeout(const Duration(seconds: 3));

        if (result?['isBlocking'] == true) {
          final sessionType = result!['sessionType'] as String? ?? 'manual';
          debugPrint('🔄 iOS sessionType=$sessionType');

          if (sessionType == 'schedule') {
            debugPrint('🔄 iOS skipping schedule session restore');
            return;
          }

          final startTime = DateTime.fromMillisecondsSinceEpoch(
            ((result['startTime'] as double) * 1000).round(),
          );
          final minutes = result['minutes'] as int;
          final totalSeconds = minutes * 60;
          final remaining = totalSeconds -
              DateTime.now().difference(startTime).inSeconds;

          if (remaining > 0) {
            state = state.copyWith(
              phase: BlockingPhase.active,
              remainingSeconds: remaining,
              selectedMinutes: minutes,
              sessionStartTime: startTime,
            );
            _startSessionTimer(totalSeconds, startTime);
          } else {
            await _blockingService.stopAllMonitoring();
          }
        }
      } else {
        final prefs = await SharedPreferences.getInstance()
            .timeout(const Duration(seconds: 3));

        final isBlocking = prefs.getBool('isBlocking') ?? false;
        final sessionType = prefs.getString('sessionType') ?? 'manual';

        debugPrint('🔄 isBlocking=$isBlocking sessionType=$sessionType');

        if (isBlocking && sessionType == 'manual') {
          final startTimeMs = prefs.getInt('sessionStartTime') ?? 0;
          final minutes = prefs.getInt('sessionMinutes') ?? 30;

          if (startTimeMs == 0 || minutes == 0) {
            await prefs.setBool('isBlocking', false);
            return;
          }

          final startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMs);
          final totalSeconds = minutes * 60;
          final remaining = totalSeconds -
              DateTime.now().difference(startTime).inSeconds;

          if (remaining > 0) {
            debugPrint('🔄 Restoring manual session — ${remaining}s remaining');
            state = state.copyWith(
              phase: BlockingPhase.active,
              remainingSeconds: remaining,
              selectedMinutes: minutes,
              sessionStartTime: startTime,
            );
            _startSessionTimer(totalSeconds, startTime);
          } else {
            await _blockingService.stopAllMonitoring();
            await prefs.setBool('isBlocking', false);
          }
        }
      }
    } catch (e) {
      debugPrint('❌ restore session error: $e');
      try {
        if (!Platform.isIOS) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isBlocking', false);
        }
      } catch (_) {}
    }
  }

  void _startSessionTimer(int totalSeconds, DateTime startTime) {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final elapsed = DateTime.now().difference(startTime).inSeconds;
      final remaining = totalSeconds - elapsed;
      if (remaining <= 0) {
        timer.cancel();
        _onSessionComplete();
      } else {
        state = state.copyWith(remainingSeconds: remaining);
      }
    });
  }

  // ── Getters ───────────────────────────────────────
  BlockingRepository get _blockingRepo => ref.read(blockingRepositoryProvider);
  BlockSessionRepository get _sessionRepo => ref.read(blockSessionRepositoryProvider);
  UsageStreakRepo get _usageRepo => ref.read(usageRepositoryProvider);
  BlockingService get _blockingService => ref.read(blockingServiceProvider);

  static const _methodChannel = MethodChannel('com.eagle.pausenow/block');

  void clearError() {
    state = state.copyWith(error: null);
  }
}