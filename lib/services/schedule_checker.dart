import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/hivebox_names.dart';
import '../data/models/schedule.dart';
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
    final schedules = box.values.where((s) => s.isActive).toList();

    debugPrint('📅 _check() fired — ${schedules.length} total schedules');

    final activeSchedules = schedules.where((s) => s.isActive).toList();
    debugPrint('📅 ${activeSchedules.length} active schedules');

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final currentDay = now.weekday - 1; // 0=Mon ... 6=Sun

    debugPrint('📅 Current time: ${now.hour}:${now.minute} day=$currentDay minutes=$currentMinutes');

    Schedule? matchingSchedule;

    for (final s in schedules) {
      if (!s.days.contains(currentDay)) continue;

      final startParts = s.startTime.split(':');
      final endParts = s.endTime.split(':');

      final startMinutes =
          int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMinutes =
          int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

      debugPrint('📅 Schedule "${s.name}": days=${s.days} start=$startMinutes end=$endMinutes');
      debugPrint('📅   currentDay match: ${s.days.contains(currentDay)}');
      debugPrint('📅   time match: $currentMinutes >= $startMinutes && $currentMinutes < $endMinutes = ${currentMinutes >= startMinutes && currentMinutes < endMinutes}');
      if (currentMinutes >= startMinutes &&
          currentMinutes < endMinutes) {
        matchingSchedule = s;
        break;
      }
    }

    if (matchingSchedule != null) {
      // should be blocking
      if (!_isScheduleBlocking ||
          _activeScheduleId != matchingSchedule.id) {
        _startScheduleBlocking(matchingSchedule);
      }
    } else {
      // should not be blocking
      if (_isScheduleBlocking) {
        _stopScheduleBlocking();
      }
    }
    // in ScheduleChecker._check()
    debugPrint('📅 Checking schedules at ${DateTime.now().hour}:${DateTime.now().minute} day $currentDay');
    debugPrint('📅 Found ${schedules.length} active schedules');
  }

  void _startScheduleBlocking(Schedule schedule) {
    if (_blockingService == null) return;
    debugPrint('📅 Schedule starting: ${schedule.name}');

    _blockingService!.setBlockingMode(schedule.blockingType);

    if (Platform.isIOS) {
      // iOS reads saved FamilyControls tokens from UserDefaults
      // just trigger startMonitoring with ios_apps placeholder
      _blockingService!.startMonitoring('ios_apps', 999);
    } else {
      // Android — pass actual package names
      final apps = schedule.blockingType ==
          AppConstants.blockingTypeSpecificApps
          ? schedule.blockedApps
          : schedule.allowedApps;

      if (apps.isEmpty) {
        debugPrint('📅 Schedule has no apps — skipping');
        return;
      }

      for (final pkg in apps) {
        _blockingService!.startMonitoring(pkg, 999);
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