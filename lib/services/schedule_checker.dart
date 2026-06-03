import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/hivebox_names.dart';
import '../data/models/schedule.dart';
import '../domain/platform/android_blocking_service.dart';
import '../domain/platform/blocking_service.dart';

class ScheduleChecker {
  ScheduleChecker._();
  static final instance = ScheduleChecker._();

  Timer? _timer;
  BlockingService? _blockingService;
  bool _isScheduleBlocking = false;
  String? _activeScheduleId;
  VoidCallback? onScheduleStarted;
  VoidCallback? onScheduleStopped;


  void start(BlockingService blockingService) {
    _blockingService = blockingService;
    _timer?.cancel();

    debugPrint('📅 ScheduleChecker started');


    // check every minute
    _timer = Timer.periodic(
      const Duration(minutes: 1),
          (_) => _check(),
    );

    // check immediately on start
    _check();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void checkNow() {
    debugPrint('📅 checkNow() called');
    _check();
  }

  void _check() {
    final box = Hive.box<Schedule>(HiveBoxNames.schedules);
    final schedules = box.values.toList();

    debugPrint('📅 _check() fired — ${schedules.length} total schedules');

    final activeSchedules = schedules.where((s) => s.isActive).toList();
    debugPrint('📅 ${activeSchedules.length} active schedules');

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final currentDay = now.weekday - 1; // 0=Mon ... 6=Sun
    // previous day for overnight check
    final previousDay = (currentDay - 1 + 7) % 7;

    debugPrint('📅 Current time: ${now.hour}:${now.minute} day=$currentDay minutes=$currentMinutes');

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
        // overnight schedule: e.g. 22:00 - 05:00
        // two cases:
        // 1. current time is AFTER start (same day)
        //    e.g. 23:00 >= 22:00 AND day matches start day
        // 2. current time is BEFORE end (next day)
        //    e.g. 02:00 < 05:00 AND previous day matches schedule days
        if (currentMinutes >= startMinutes &&
            schedule.days.contains(currentDay)) {
          matches = true;
          debugPrint('📅 Overnight match (after start): ${schedule.name}');
        } else if (currentMinutes < endMinutes &&
            schedule.days.contains(previousDay)) {
          matches = true;
          debugPrint('📅 Overnight match (before end next day): ${schedule.name}');
        }
      } else {
        // normal schedule: e.g. 09:00 - 17:00
        if (currentMinutes >= startMinutes &&
            currentMinutes < endMinutes &&
            schedule.days.contains(currentDay)) {
          matches = true;
          debugPrint('📅 Normal match: ${schedule.name}');
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
    debugPrint('📅 Schedule starting: ${schedule.name}');
    debugPrint('📅 _startScheduleBlocking: ${schedule.name}');
    debugPrint('📅 blockingType: ${schedule.blockingType}');
    debugPrint('📅 blockedApps: ${schedule.blockedApps}');
    debugPrint('📅 allowedApps: ${schedule.allowedApps}');
    _blockingService!.setBlockingMode(schedule.blockingType);

    if (Platform.isIOS) {
      _blockingService!.startMonitoring('ios_apps', 999);
    } else {
      final apps = schedule.blockingType ==
          AppConstants.blockingTypeSpecificApps
          ? schedule.blockedApps
          : schedule.allowedApps;

      debugPrint('📅 apps to monitor: $apps');
      debugPrint('📅 apps isEmpty: ${apps.isEmpty}');

      if (apps.isEmpty) {
        debugPrint('📅 Schedule has no apps — skipping');
        return;
      }

      for (final pkg in apps) {
        await _blockingService!.startMonitoring(pkg, 999);
      }

      // mark as schedule so _restoreSession ignores it
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
  }

  bool get isScheduleBlocking => _isScheduleBlocking;
  String? get activeScheduleId => _activeScheduleId;
}