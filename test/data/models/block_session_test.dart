import 'package:flutter_test/flutter_test.dart';
import 'package:pausenow/data/models/block_session.dart';

void main() {
  group('BlockSession.duration', () {
    test('uses activeSeconds directly when present', () {
      final session = BlockSession(
        startTime: DateTime(2026, 1, 1, 9, 0),
        endTime: DateTime(2026, 1, 1, 9, 30),
        blockingType: 'specific_apps',
        selectedMinutes: 10, // deliberately mismatched with the elapsed time
        completed: true,
        activeSeconds: 245,
      );

      // activeSeconds is the source of truth once recorded — the
      // start/end/selectedMinutes fields must not override it.
      expect(session.duration, const Duration(seconds: 245));
    });

    test('falls back to elapsed time for legacy sessions without activeSeconds', () {
      final session = BlockSession(
        startTime: DateTime(2026, 1, 1, 9, 0),
        endTime: DateTime(2026, 1, 1, 9, 20),
        blockingType: 'specific_apps',
        selectedMinutes: 30,
        completed: false,
      );

      expect(session.duration, const Duration(minutes: 20));
    });

    test('caps a completed legacy session at the configured minutes', () {
      final session = BlockSession(
        startTime: DateTime(2026, 1, 1, 9, 0),
        // ran long, but was marked completed
        endTime: DateTime(2026, 1, 1, 10, 0),
        blockingType: 'specific_apps',
        selectedMinutes: 30,
        completed: true,
      );

      expect(session.duration, const Duration(minutes: 30));
    });

    test('an incomplete legacy session without an end time uses elapsed-to-now, uncapped', () {
      final start = DateTime.now().subtract(const Duration(minutes: 45));
      final session = BlockSession(
        startTime: start,
        blockingType: 'specific_apps',
        selectedMinutes: 30,
        completed: false,
      );

      // not completed, so it's NOT capped at selectedMinutes even though
      // it has run past it — this is what lets an in-progress "all apps"
      // session keep counting on the home screen.
      expect(session.duration.inMinutes, greaterThanOrEqualTo(45));
    });
  });

  group('BlockSession.isToday', () {
    test('true for a session started today', () {
      final session = BlockSession(
        startTime: DateTime.now(),
        blockingType: 'specific_apps',
        selectedMinutes: 30,
      );
      expect(session.isToday, isTrue);
    });

    test('false for a session started on a previous day', () {
      final session = BlockSession(
        startTime: DateTime.now().subtract(const Duration(days: 1)),
        blockingType: 'specific_apps',
        selectedMinutes: 30,
      );
      expect(session.isToday, isFalse);
    });
  });
}
