import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import '../../../core/constants/hivebox_names.dart';
import '../../../data/models/schedule.dart';
import 'schedule_state.dart';

part 'schedule_viewmodel.g.dart';

@riverpod
class ScheduleViewModel extends _$ScheduleViewModel {

  Box<Schedule> get _box =>
      Hive.box<Schedule>(HiveBoxNames.schedules);

  @override
  ScheduleState build() {
    Future.microtask(() => loadSchedules());
    return const ScheduleState(isLoading: true);
  }

  void loadSchedules() {
    try {
      final schedules = _box.values.toList();
      state = state.copyWith(
        schedules: schedules,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
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

      await _box.put(schedule.id, schedule);
      loadSchedules();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteSchedule(String id) async {
    await _box.delete(id);
    loadSchedules();
  }

  Future<void> toggleSchedule(String id) async {
    final schedule = _box.get(id);
    if (schedule == null) return;
    schedule.isActive = !schedule.isActive;
    await schedule.save();
    loadSchedules();
  }
}