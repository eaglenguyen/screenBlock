import 'package:flutter/material.dart';

enum ScheduleStone { name, time, apps, days }

class ScheduleGauntletState {
  String? name;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  List<String> apps = [];
  List<int> days = []; // 0 = Monday ... 6 = Sunday

  bool get hasName => name != null && name!.isNotEmpty;
  bool get hasTime => startTime != null && endTime != null;
  bool get hasApps => apps.isNotEmpty;
  bool get hasDays => days.isNotEmpty;

  bool isFilled(ScheduleStone stone) {
    switch (stone) {
      case ScheduleStone.name:
        return hasName;
      case ScheduleStone.time:
        return hasTime;
      case ScheduleStone.apps:
        return hasApps;
      case ScheduleStone.days:
        return hasDays;
    }
  }

  String get timeLabel {
    if (!hasTime) return '--:-- - --:--';
    String fmt(TimeOfDay t) {
      final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
      final m = t.minute.toString().padLeft(2, '0');
      final period = t.period == DayPeriod.am ? 'AM' : 'PM';
      return '$h:$m $period';
    }
    return '${fmt(startTime!)} - ${fmt(endTime!)}';
  }

  String get appsLabel => hasApps ? '${apps.length} apps' : '-- apps';

  String get daysLabel {
    if (!hasDays) return '---';
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (days.length == 7) return 'Every day';
    if (days.toSet().containsAll({0, 1, 2, 3, 4}) && days.length == 5) return 'Weekdays';
    final sorted = List<int>.from(days)..sort();
    return sorted.map((d) => names[d]).join(', ');
  }
}