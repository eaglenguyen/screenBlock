import '../models/schedule.dart';

abstract class ScheduleRepository {
  List<Schedule> getAllSchedules();
  Schedule? getSchedule(String id);
  Future<void> saveSchedule(Schedule schedule);
  Future<void> deleteSchedule(String id);

  // 👇 the specific operation HomeViewModel needs on premium loss
  Future<List<String>> downgradeAllAppsSchedules();
}