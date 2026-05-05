import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:screenblock/data/repositories/BlockingRepo.dart';
import '../../../data/models/timer_config.dart';
import '../../../domain/platform/blocking_service.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/blocking_service_provider.dart';
import 'timer_state.dart';

part 'timer_viewmodel.g.dart';

@riverpod
class TimerViewModel extends _$TimerViewModel {

  @override
  TimerState build() => const TimerState();

  BlockingRepository get _repo =>
      ref.read(blockingRepositoryProvider);

  BlockingService get _service =>
      ref.read(blockingServiceProvider);

  // ── Setup ───────────────────────────────────────
  // called when user picks an app from AppPicker
  void setApp(String packageName, String appName) {
    // load existing config if app already tracked
    final existing = _repo.getTimer(packageName);

    state = state.copyWith(
      packageName: packageName,
      appName: appName,
      selectedMinutes: existing?.limitMinutes ?? 30,
    );
  }

  // ── Config ──────────────────────────────────────
  void setMinutes(int minutes) {
    state = state.copyWith(selectedMinutes: minutes);
  }



  // ── Save ────────────────────────────────────────
  Future<void> saveTimer() async {
    if (state.packageName == null) return;

    state = state.copyWith(isSaving: true);

    try {
      final config = TimerConfig(
        packageName: state.packageName!,
        appName: state.appName ?? '',
        limitMinutes: state.selectedMinutes,
        isActive: true,
      );

      await _repo.saveTimer(config);
      await _service.startMonitoring(
        config.packageName,
        config.limitMinutes,
      );

      state = state.copyWith(
        isSaving: false,
        isSaved: true,
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString(),
      );
    }
  }

  // ── Helper ──────────────────────────────────────


  void resetSaved() {
    state = state.copyWith(isSaved: false);
  }
}