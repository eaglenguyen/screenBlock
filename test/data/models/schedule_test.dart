import 'package:flutter_test/flutter_test.dart';
import 'package:pausenow/data/models/schedule.dart';

Schedule _schedule({
  String startTime = '09:00',
  String endTime = '17:00',
  List<int> days = const [0, 1, 2, 3, 4],
}) {
  return Schedule(
    id: 'test-id',
    name: 'Test schedule',
    startTime: startTime,
    endTime: endTime,
    days: days,
    blockingType: 'specific_apps',
  );
}

void main() {
  group('Schedule.timeRange', () {
    test('renders "All Day" for the 00:00–23:59 special case', () {
      final schedule = _schedule(startTime: '00:00', endTime: '23:59');
      expect(schedule.timeRange, 'All Day');
    });

    test('formats a normal range with AM/PM', () {
      final schedule = _schedule(startTime: '09:00', endTime: '17:30');
      expect(schedule.timeRange, '9:00 AM - 5:30 PM');
    });

    test('formats midnight and noon correctly (12, not 0)', () {
      final schedule = _schedule(startTime: '00:30', endTime: '12:00');
      expect(schedule.timeRange, '12:30 AM - 12:00 PM');
    });
  });

  group('Schedule.daysDisplay', () {
    test('all 7 days reads "Every day"', () {
      final schedule = _schedule(days: const [0, 1, 2, 3, 4, 5, 6]);
      expect(schedule.daysDisplay, 'Every day');
    });

    test('Mon–Fri reads "Weekdays"', () {
      final schedule = _schedule(days: const [0, 1, 2, 3, 4]);
      expect(schedule.daysDisplay, 'Weekdays');
    });

    test('Sat+Sun reads "Weekends"', () {
      final schedule = _schedule(days: const [5, 6]);
      expect(schedule.daysDisplay, 'Weekends');
    });

    test('an arbitrary subset lists day-letter initials in order', () {
      final schedule = _schedule(days: const [0, 2, 4]); // Mon, Wed, Fri
      expect(schedule.daysDisplay, 'M W F');
    });
  });

  group('Schedule.copyWith', () {
    test('overrides only the given fields and always refreshes updatedAt', () {
      final original = _schedule();
      final beforeCopy = DateTime.now();

      final updated = original.copyWith(name: 'Renamed');

      expect(updated.name, 'Renamed');
      expect(updated.startTime, original.startTime); // untouched
      expect(updated.days, original.days); // untouched
      // known behavior: updatedAt is stamped to "now" on every copyWith,
      // even when updatedAt itself wasn't one of the changed fields.
      expect(
        updated.updatedAt.isAfter(beforeCopy.subtract(const Duration(seconds: 1))),
        isTrue,
      );
    });
  });
}
