import 'package:flutter/cupertino.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/constants/hivebox_names.dart';
import '../../../data/models/schedule.dart';
import '../../../providers/repository_providers.dart'; // 👈 wherever scheduleRepositoryProvider lives
import '../../../services/schedule_checker.dart';
import '../../data/repositories/ScheduleRepo.dart';
import 'schedule_state.dart';

part 'schedule_viewmodel.g.dart';

@riverpod
class ScheduleViewModel extends _$ScheduleViewModel {

  ScheduleRepository get _repo => ref.read(scheduleRepositoryProvider); // 👈 replaces _box getter

  @override
  ScheduleState build() {
    Future.microtask(() => loadSchedules());
    return const ScheduleState(isLoading: true);
  }

  void loadSchedules() {
    try {
      final allSchedules = _repo.getAllSchedules(); // 👈 was _box.values.toList()
      final order = _getOrder();

      List<Schedule> ordered;

      if (order.isEmpty) {
        ordered = allSchedules;
      } else {
        final orderedById = {for (final s in allSchedules) s.id: s};
        ordered = [
          ...order
              .where((id) => orderedById.containsKey(id))
              .map((id) => orderedById[id]!),
          ...allSchedules.where((s) => !order.contains(s.id)),
        ];
      }

      _saveOrderFromList(ordered);

      state = state.copyWith(
        schedules: ordered,
        isLoading: false,
      );
      ScheduleChecker.instance.checkNow();
    } catch (e) {
      debugPrint('❌ loadSchedules error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _saveOrderFromList(List<Schedule> schedules) {
    final box = Hive.box(HiveBoxNames.settings);
    box.put('scheduleOrder', schedules.map((s) => s.id).toList());
  }

  Future<void> saveSchedule({
    String? existingId,
    required String name,
    required String startTime,
    required String endTime,
    required List<int> days,
    required String blockingType,
    required List<String> blockedApps,
    required List<String> allowedApps,
  }) async {
    try {
      final isNewSchedule = existingId == null;

      final schedule = Schedule(
        id: existingId ?? const Uuid().v4(),
        name: name,
        startTime: startTime,
        endTime: endTime,
        days: days,
        blockingType: blockingType,
        blockedApps: blockedApps,
        allowedApps: allowedApps,
      );

      await _repo.saveSchedule(schedule); // 👈 was _box.put(schedule.id, schedule)

      if (isNewSchedule) {
        await AnalyticsService.instance.captureOnce(AnalyticsEvents.firstBlockCreated);
      }

      if (ScheduleChecker.instance.activeScheduleId == schedule.id) {
        debugPrint('📅 Active schedule updated — restarting blocking');
        await ScheduleChecker.instance.restartActiveSchedule(schedule);
      }
      _saveOrder();
      loadSchedules();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteSchedule(String id) async {
    await _repo.deleteSchedule(id); // 👈 was _box.delete(id)
    loadSchedules();
  }

  Future<void> toggleSchedule(String id) async {
    final schedule = _repo.getSchedule(id); // 👈 was _box.get(id)
    if (schedule == null) return;
    final updated = schedule.copyWith(isActive: !schedule.isActive); // 👈 was mutate + schedule.save()
    await _repo.saveSchedule(updated);
    //ScheduleChecker.instance.checkNow();

    loadSchedules();
  }

  // Reordering list

  List<String> _getOrder() {
    final box = Hive.box(HiveBoxNames.settings);
    return List<String>.from(box.get('scheduleOrder', defaultValue: <String>[]));
  }

  void _saveOrder() {
    _saveOrderFromList(state.schedules);
  }

  void reorderSchedules(int oldIndex, int newIndex) {
    final schedules = List<Schedule>.from(state.schedules);
    if (newIndex > oldIndex) newIndex--;
    final item = schedules.removeAt(oldIndex);
    schedules.insert(newIndex, item);
    state = state.copyWith(schedules: schedules);
    final box = Hive.box(HiveBoxNames.settings);
    box.put('scheduleOrder', schedules.map((s) => s.id).toList());
  }

}