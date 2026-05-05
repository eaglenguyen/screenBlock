import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:screenblock/data/repositoryImpl/UsageStreakRepo.dart';

import '../../../domain/platform/blocking_service.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/blocking_service_provider.dart';
import '../../data/models/timer_config.dart';
import '../../data/repositories/BlockingRepo.dart';
import 'home_state.dart';

part 'home_viewmodel.g.dart';


@riverpod
class HomeViewModel extends _$HomeViewModel {

  @override
  HomeState build() {
    // load data the moment this viewmodel is created
    _init();
    return const HomeState(isLoading: true);
  }

  BlockingRepository get _blockingRepo =>
      ref.read(blockingRepositoryProvider);

  UsageStreakRepo get _usageRepo =>
      ref.read(usageRepositoryProvider);

  BlockingService get _blockingService =>
      ref.read(blockingServiceProvider);

  // ── Init ────────────────────────────────────────
  void _init() {
    loadTrackedApps();
    _listenToUsageEvents();
  }

  // ── Load ────────────────────────────────────────
  void loadTrackedApps() {
    try {
      final timers = _blockingRepo.getAllTimers();
      final streak = _usageRepo.getStreak();
      state = state.copyWith(
        trackedApps: timers,
        streak: streak,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // ── Add / remove ────────────────────────────────
  Future<void> addTrackedApp(TimerConfig config) async {
    try {
      // check free tier limit
      if (_blockingRepo.hasReachedFreeLimit()) {
        state = state.copyWith(
          error: 'free_limit_reached', // UI checks this string
        );
        return;
      }

      await _blockingRepo.saveTimer(config);
      await _blockingService.startMonitoring(
        config.packageName,
        config.limitMinutes,
      );

      loadTrackedApps(); // refresh list
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> removeTrackedApp(String packageName) async {
    try {
      await _blockingRepo.deleteTimer(packageName);
      await _blockingService.stopMonitoring(packageName);
      loadTrackedApps();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ── Block / unblock ─────────────────────────────
  Future<void> blockAppForDay(String packageName) async {
    try {
      await _blockingRepo.blockApp(packageName);
      await _blockingService.blockApp(packageName);
      loadTrackedApps();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> unblockApp(String packageName) async {
    try {
      await _blockingRepo.unblockApp(packageName);
      await _blockingService.unblockApp(packageName);
      loadTrackedApps();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ── Usage event listener ────────────────────────
  // listens to the blocking service stream
  // triggers interrupt overlay when timer expires
  void _listenToUsageEvents() {
    ref.listen(
      blockingServiceProvider,
          (previous, next) {},
    );

    _blockingService.usageEvents.listen((event) {
      switch (event.type) {
        case AppEventType.timerExpired:
          state = state.copyWith(
            error: 'timer_expired:${event.packageName}',
          );
          break;
        case AppEventType.timerWarning:
          state = state.copyWith(
            error: 'timer_warning:${event.packageName}',
          );
          break;
        default:
          break;
      }
    });
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}