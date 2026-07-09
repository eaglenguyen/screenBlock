import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/hivebox_names.dart';
import '../models/schedule.dart';
import '../repositories/ScheduleRepo.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {

  Box<Schedule> get _box => Hive.box<Schedule>(HiveBoxNames.schedules);

  @override
  List<Schedule> getAllSchedules() {
    return _box.values.toList();
  }

  @override
  Schedule? getSchedule(String id) {
    return _box.get(id);
  }

  @override
  Future<void> saveSchedule(Schedule schedule) async {
    await _box.put(schedule.id, schedule);
  }

  @override
  Future<void> deleteSchedule(String id) async {
    await _box.delete(id);
  }

  @override
  Future<List<String>> downgradeAllAppsSchedules() async {
    final changedIds = <String>[];
    for (final key in _box.keys) {
      final schedule = _box.get(key);
      if (schedule != null &&
          schedule.blockingType == AppConstants.blockingTypeAllApps) {
        final updated = schedule.copyWith(
          blockingType: AppConstants.blockingTypeSpecificApps,
        );
        await _box.put(key, updated);
        changedIds.add(schedule.id);
      }
    }
    return changedIds;
  }
}