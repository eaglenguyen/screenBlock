import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/hivebox_names.dart';
import '../data/models/schedule.dart';
import '../data/repositoryImpl/block_session_repository.dart';
import '../domain/platform/android_blocking_service.dart';
import '../domain/blocking_service.dart';
import '../domain/platform/ios_blocking_service.dart';

class ScheduleChecker {
  ScheduleChecker._();
  static final instance = ScheduleChecker._();

  Timer? _timer;
  Timer? _pauseTimer;
  Timer? _activeTickTimer; // 👈 new — drives the accumulator
  BlockingService? _blockingService;
  BlockSessionRepository? _sessionRepo; // 👈 new
  String? _activeSessionKey; // 👈 new
  int _activeSecondsAccumulator = 0; // 👈 new
  bool _isScheduleBlocking = false;
  bool _isPaused = false;
  String? _activeScheduleId;
  Schedule? _activeSchedule;
  DateTime? _pauseEndsAt;
  bool Function()? isPremium;
  bool Function()? isManualBlocking;

  VoidCallback? onScheduleStarted;
  VoidCallback? onScheduleStopped;
  VoidCallback? onSchedulePaused;
  VoidCallback? onScheduleResumed;
  void Function(int remainingSeconds)? onPauseTickChanged;

  void start(BlockingService blockingService, BlockSessionRepository sessionRepo) { // 👈 new param
    _blockingService = blockingService;
    _sessionRepo = sessionRepo; // 👈 new
    _timer?.cancel();
    debugPrint('📅 ScheduleChecker started');
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _check());
    _check();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _pauseTimer?.cancel();
    _pauseTimer = null;
    _activeTickTimer?.cancel(); // 👈 new
    _activeTickTimer = null;
  }

  void checkNow() {
    _check();
  }

  // 👇 new — starts/resumes the accumulator tick
  void _startActiveTick() {
    _activeTickTimer?.cancel();
    _activeTickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _activeSecondsAccumulator++;
    });
  }

  // 👇 new — stops the accumulator tick (called on pause)
  void _stopActiveTick() {
    _activeTickTimer?.cancel();
    _activeTickTimer = null;
  }

  Future<void> pauseFor(int minutes) async {
    debugPrint('📅 Schedule paused for $minutes minutes');

    _isPaused = true;
    _isScheduleBlocking = true;
    _pauseEndsAt = DateTime.now().add(Duration(minutes: minutes));
    _stopActiveTick(); // 👈 new — freeze the accumulator

    if (Platform.isIOS) {
      await (_blockingService as IOSBlockingService).pauseBlocking(minutes);
    } else {
      _blockingService?.stopAllMonitoring();
      await _savePauseEndTimeNative(_pauseEndsAt!);
    }

    onSchedulePaused?.call();

    _pauseTimer?.cancel();
    _pauseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_pauseEndsAt == null) {
        timer.cancel();
        return;
      }
      final remaining = _pauseEndsAt!.difference(DateTime.now()).inSeconds;
      if (remaining <= 0) {
        timer.cancel();
        _resumeFromPause();
      } else {
        onPauseTickChanged?.call(remaining);
      }
    });
  }

  Future<void> _savePauseEndTimeNative(DateTime pauseEndsAt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('schedulePauseEndTime', pauseEndsAt.millisecondsSinceEpoch);

      if (Platform.isAndroid && _blockingService is AndroidBlockingService) {
        await (_blockingService as AndroidBlockingService)
            .savePauseEndTime(pauseEndsAt.millisecondsSinceEpoch);
      }
      if (Platform.isIOS && _blockingService is IOSBlockingService) {
        await (_blockingService as IOSBlockingService)
            .savePauseEndTime(pauseEndsAt.millisecondsSinceEpoch);
      }
    } catch (e) {
      debugPrint('❌ save pause end time error: $e');
    }
  }

  Future<void> resumeNow() async {
    _pauseTimer?.cancel();
    if (Platform.isIOS) {
      await (_blockingService as IOSBlockingService).resumeBlocking();
    }
    _resumeFromPause();
  }

  void _resumeFromPause() {
    if (!_isPaused) return;
    debugPrint('📅 Schedule resuming from pause');
    _isPaused = false;
    _pauseEndsAt = null;
    _startActiveTick(); // 👈 new — resume the accumulator

    if (Platform.isIOS) {
      (_blockingService as IOSBlockingService).resumeBlocking();
    } else if (_activeSchedule != null) {
      _startScheduleBlocking(_activeSchedule!); // note: this re-runs startSession — see caveat below
    }

    onScheduleResumed?.call();
  }

  void _check() {
    if (isManualBlocking != null && isManualBlocking!()) {
      debugPrint('⏭️ schedule check skipped — manual blocking active');
      return;
    }
    if (_isPaused) {
      final box = Hive.box<Schedule>(HiveBoxNames.schedules);
      final activeSchedule = box.get(_activeScheduleId ?? '');
      if (activeSchedule == null || !activeSchedule.isActive) {
        debugPrint('📅 Active schedule disabled while paused — stopping');
        _stopScheduleBlocking();
      }
      return;
    }

    final box = Hive.box<Schedule>(HiveBoxNames.schedules);
    final schedules = box.values.toList();
    final activeSchedules = schedules.where((s) => s.isActive).toList();

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final currentDay = now.weekday - 1;
    final previousDay = (currentDay - 1 + 7) % 7;

    Schedule? matchingSchedule;
    final premium = isPremium?.call() ?? false;
    final allowedSchedules = premium ? activeSchedules : activeSchedules.take(1).toList();

    for (final schedule in allowedSchedules) {
      final startParts = schedule.startTime.split(':');
      final endParts = schedule.endTime.split(':');
      final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      final isOvernight = endMinutes < startMinutes;
      bool matches = false;

      if (isOvernight) {
        if (currentMinutes >= startMinutes && schedule.days.contains(currentDay)) {
          matches = true;
        } else if (currentMinutes < endMinutes && schedule.days.contains(previousDay)) {
          matches = true;
        }
      } else {
        if (currentMinutes >= startMinutes &&
            currentMinutes < endMinutes &&
            schedule.days.contains(currentDay)) {
          matches = true;
        }
      }

      if (matches) {
        matchingSchedule = schedule;
        break;
      }
    }

    if (matchingSchedule != null) {
      if (!_isScheduleBlocking || _activeScheduleId != matchingSchedule.id) {
        _startScheduleBlocking(matchingSchedule);
      }
    } else {
      if (_isScheduleBlocking) {
        _stopScheduleBlocking();
      }
    }
  }

  Future<void> _startScheduleBlocking(Schedule schedule) async {
    if (_blockingService == null) return;

    // 👇 new — only start a fresh session/accumulator if this is a genuinely new activation,
    // not a resume-from-pause re-entry (guarded by checking if we already have a key for this schedule)
    final isNewActivation = _activeSessionKey == null || _activeScheduleId != schedule.id;

    _blockingService!.setBlockingMode(schedule.blockingType);
    _activeSchedule = schedule;

    if (isNewActivation && _sessionRepo != null) {
      _activeSecondsAccumulator = 0; // 👈 new — reset for a fresh session
      _activeSessionKey = await _sessionRepo!.startSession(
        blockingType: schedule.blockingType,
        selectedMinutes: 0, // not meaningful for schedules — activeSeconds is the source of truth now
      );
    }

    if (Platform.isIOS) {
      await (_blockingService as IOSBlockingService)
          .startMonitoring('ios_apps', 999, sessionType: 'schedule', blockingMode: schedule.blockingType, scheduleId: schedule.id);
    } else {
      final allApps = schedule.blockingType == AppConstants.blockingTypeSpecificApps
          ? schedule.blockedApps
          : schedule.allowedApps;
      final premium = isPremium?.call() ?? false;
      final apps = premium ? allApps : allApps.take(3).toList();
      if (apps.isEmpty) return;

      for (final pkg in apps) {
        await _blockingService!.startMonitoring(pkg, 999);
      }

      if (_blockingService is AndroidBlockingService) {
        await (_blockingService as AndroidBlockingService).persistBlockingState(
          sessionMinutes: 999,
          sessionType: 'schedule',
        );
        await (_blockingService as AndroidBlockingService).checkCurrentForegroundApp();
      }
    }

    _isScheduleBlocking = true;
    _activeScheduleId = schedule.id;
    _startActiveTick(); // 👈 new — start ticking (safe to call even on resume, just restarts the timer)
    onScheduleStarted?.call();
  }

  void _stopScheduleBlocking() {
    if (_blockingService == null) return;
    debugPrint('📅 Schedule ending — stopping blocking');

    _stopActiveTick(); // 👈 new

    // 👇 new — write the final accumulated active time
    if (_sessionRepo != null && _activeSessionKey != null) {
      _sessionRepo!.endSession(
        key: _activeSessionKey!,
        completed: true,
        activeSeconds: _activeSecondsAccumulator,
      );
      _activeSessionKey = null;
      _activeSecondsAccumulator = 0;
    }

    _pauseTimer?.cancel();
    _pauseTimer = null;
    _isPaused = false;
    _pauseEndsAt = null;
    onPauseTickChanged?.call(0);

    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('schedulePauseEndTime');
    });

    _blockingService!.stopAllMonitoring();
    _isScheduleBlocking = false;
    _activeScheduleId = null;
    _activeSchedule = null;
    onScheduleStopped?.call();
    onScheduleResumed?.call();
  }

  Future<void> restartActiveSchedule(Schedule schedule) async {
    if (_blockingService == null) return;
    debugPrint('📅 Restarting blocking with updated app list');
    _blockingService!.stopAllMonitoring();
    await Future.delayed(const Duration(milliseconds: 300));
    await _startScheduleBlocking(schedule); // note: isNewActivation check prevents accumulator reset here, since scheduleId is unchanged
  }

  bool get isScheduleBlocking => _isScheduleBlocking;
  bool get isPaused => _isPaused;
  DateTime? get pauseEndsAt => _pauseEndsAt;
  String? get activeScheduleId => _activeScheduleId;
}