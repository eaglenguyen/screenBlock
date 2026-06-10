import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/hivebox_names.dart';
import '../data/models/schedule.dart';
import '../domain/platform/android_blocking_service.dart';
import '../domain/platform/blocking_service.dart';
import '../domain/platform/ios_blocking_service.dart';

class ScheduleChecker {
  ScheduleChecker._();
  static final instance = ScheduleChecker._();

  Timer? _timer;
  Timer? _pauseTimer;
  BlockingService? _blockingService;
  bool _isScheduleBlocking = false;
  bool _isPaused = false;
  String? _activeScheduleId;
  Schedule? _activeSchedule;
  DateTime? _pauseEndsAt;

  VoidCallback? onScheduleStarted;
  VoidCallback? onScheduleStopped;
  VoidCallback? onSchedulePaused;
  VoidCallback? onScheduleResumed;
  // fires every second while paused with remaining seconds
  void Function(int remainingSeconds)? onPauseTickChanged;

  void start(BlockingService blockingService) {
    _blockingService = blockingService;
    _timer?.cancel();
    debugPrint('📅 ScheduleChecker started');
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _check());

    _check();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _pauseTimer?.cancel();
    _pauseTimer = null;
  }

  void checkNow() {
    _check();
  }

  Future<void> pauseFor(int minutes) async {
    debugPrint('📅 Schedule paused for $minutes minutes');

    _isPaused = true;
    _isScheduleBlocking = true;
    _pauseEndsAt = DateTime.now().add(Duration(minutes: minutes));

    if (Platform.isIOS) {
      // iOS: pauseBlocking handles unshielding + native timer
      // do NOT call stopAllMonitoring after this
      await (_blockingService as IOSBlockingService).pauseBlocking(minutes);
    } else {
      // Android: stop monitoring then save pause time
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
      await prefs.setInt(
        'schedulePauseEndTime',
        pauseEndsAt.millisecondsSinceEpoch,
      );

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

    if (Platform.isIOS) {
      // re-shield directly via resumeBlocking
      // in case Swift Timer or DeviceActivity didn't fire
      (_blockingService as IOSBlockingService).resumeBlocking();
    } else if (_activeSchedule != null) {
      _startScheduleBlocking(_activeSchedule!);
    }

    onScheduleResumed?.call();
  }

  void _check() {
    // don't check while paused — let pause timer handle resume
    if (_isPaused) return;

    final box = Hive.box<Schedule>(HiveBoxNames.schedules);
    final schedules = box.values.toList();


    final activeSchedules = schedules.where((s) => s.isActive).toList();

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final currentDay = now.weekday - 1;
    final previousDay = (currentDay - 1 + 7) % 7;


    Schedule? matchingSchedule;

    for (final schedule in activeSchedules) {
      final startParts = schedule.startTime.split(':');
      final endParts = schedule.endTime.split(':');
      final startMinutes =
          int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMinutes =
          int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

      final isOvernight = endMinutes < startMinutes;
      bool matches = false;





      if (isOvernight) {
        if (currentMinutes >= startMinutes &&
            schedule.days.contains(currentDay)) {
          matches = true;
        } else if (currentMinutes < endMinutes &&
            schedule.days.contains(previousDay)) {
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
      if (!_isScheduleBlocking ||
          _activeScheduleId != matchingSchedule.id) {
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

    _blockingService!.setBlockingMode(schedule.blockingType);
    _activeSchedule = schedule;

    if (Platform.isIOS) {
      // 👇 pass sessionType directly instead of separate persistSessionType call
      await (_blockingService as IOSBlockingService)
          .startMonitoring('ios_apps', 999, 'schedule');
    } else {
      final apps = schedule.blockingType ==
          AppConstants.blockingTypeSpecificApps
          ? schedule.blockedApps
          : schedule.allowedApps;

      if (apps.isEmpty) return;

      for (final pkg in apps) {
        await _blockingService!.startMonitoring(pkg, 999);
      }

      if (_blockingService is AndroidBlockingService) {
        await (_blockingService as AndroidBlockingService)
            .persistBlockingState(
          sessionMinutes: 999,
          sessionType: 'schedule',
        );
      }
    }

    _isScheduleBlocking = true;
    _activeScheduleId = schedule.id;
    onScheduleStarted?.call();
  }

  void _stopScheduleBlocking() {
    if (_blockingService == null) return;
    debugPrint('📅 Schedule ending — stopping blocking');
    _blockingService!.stopAllMonitoring();
    _isScheduleBlocking = false;
    _activeScheduleId = null;
    _activeSchedule = null;
    onScheduleStopped?.call();
  }

  bool get isScheduleBlocking => _isScheduleBlocking;
  bool get isPaused => _isPaused;
  DateTime? get pauseEndsAt => _pauseEndsAt;
  String? get activeScheduleId => _activeScheduleId;
}