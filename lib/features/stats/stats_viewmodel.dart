import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:screenblock/data/repositoryImpl/UsageStreakRepo.dart';
import '../../../providers/repository_providers.dart';
import 'stats_state.dart';

part 'stats_viewmodel.g.dart';

@riverpod
class StatsViewModel extends _$StatsViewModel {

  @override
  StatsState build() {
    loadStats();
    return const StatsState(isLoading: true);
  }

  UsageStreakRepo get _repo => ref.read(usageRepositoryProvider);

  String get _todayStr {
    final now = DateTime.now();
    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  void loadStats() {
    try {
      final todayLogs = _repo.getByDate(_todayStr);
      final weeklyLogs = _repo.getLastSevenDaysGrouped();
      final streak = _repo.getStreak();

      state = state.copyWith(
        todayLogs: todayLogs,
        weeklyLogs: weeklyLogs,
        streak: streak,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshStats() async {
    await _repo.checkAndUpdateStreak();
    loadStats();
  }
}