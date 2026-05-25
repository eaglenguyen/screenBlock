import 'package:hive/hive.dart';
import '../../core/constants/hivebox_names.dart';
import '../models/block_session.dart';

class BlockSessionRepository {

  Box<BlockSession> get _box =>
      Hive.box<BlockSession>(HiveBoxNames.blockSessions);

  // ── Write ────────────────────────────────────────

  Future<String> startSession({
    required String blockingType,
    required int selectedMinutes,
  }) async {
    final session = BlockSession(
      startTime: DateTime.now(),
      blockingType: blockingType,
      selectedMinutes: selectedMinutes,
    );
    final key = await _box.add(session);
    return key.toString();
  }

  Future<void> endSession({
    required String key,
    required bool completed,
  }) async {
    final session = _box.get(int.parse(key));
    if (session == null) return;
    session.endTime = DateTime.now();
    session.completed = completed;
    await session.save();
  }

  // ── Read ─────────────────────────────────────────

  List<BlockSession> getTodaySessions() {
    return _box.values
        .where((s) => s.isToday)
        .toList();
  }

  Duration getTodayTotalDuration() {
    return getTodaySessions()
        .where((s) => s.endTime != null) // 👈 only completed sessions
        .fold(
      Duration.zero,
          (total, session) => total + session.duration,
    );
  }

  Duration getTodayCompletedDuration() {
    return getTodaySessions()
        .where((s) => s.completed && s.endTime != null)
        .fold(
      Duration.zero,
          (total, session) => total + session.duration,
    );
  }
}