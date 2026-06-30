import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../domain/platform/blocking_service.dart';
import '../../../providers/blocking_service_provider.dart';
import '../../core/constants/hivebox_names.dart';
import 'onboarding_state.dart';

part 'onboarding_viewmodel.g.dart';

@riverpod
class OnboardingViewModel extends _$OnboardingViewModel {

  @override
  OnboardingState build() {
    final box = Hive.box(HiveBoxNames.settings);
    final savedName = box.get('userName', defaultValue: '') as String;
    return OnboardingState(userName: savedName.isEmpty ? null : savedName);
  }
  BlockingService get _service => ref.read(blockingServiceProvider);

  // ── Navigation ───────────────────────────────────
  void goToStep(OnboardingStep step) {
    state = state.copyWith(currentStep: step);
  }

  // ── Personalization setters ───────────────────────
  void setUserName(String name) {
    state = state.copyWith(userName: name.trim());
    // 👇 persist immediately
    final box = Hive.box(HiveBoxNames.settings);
    box.put('userName', name.trim());
  }

  void setDailyScreenTime(String range) {
    state = state.copyWith(
      dailyScreenTime: range,
      dailyHours: _parseHours(range),
    );
  }

  void setMainStruggle(String struggle) {
    state = state.copyWith(mainStruggle: struggle);
  }

  void setGoal(String goal) {
    state = state.copyWith(goal: goal);
  }

  void setHearAboutUs(String source) {
    state = state.copyWith(hearAboutUs: source);
  }

  // ── Hours parser ──────────────────────────────────
  double _parseHours(String range) {
    switch (range) {
      case 'Less than 1 hour': return 0.5;
      case '1–2 hours':        return 1.5;
      case '2–3 hours':        return 2.5;
      case '3–4 hours':        return 3.5;
      case '4–5 hours':        return 4.5;
      case '5–6 hours':        return 5.5;
      case '6–7 hours':        return 6.5;
      case '7+ hours':         return 8.0;
      default:                 return 3.5;
    }
  }

  // ── Permissions ───────────────────────────────────
  Future<void> _checkPermissions() async {
    final hasUsage = await _service.hasUsageStatsPermission();
    final hasOverlay = await _service.hasOverlayPermission();
    final hasAccessibility =
    await _service.hasAccessibilityPermission();
    state = state.copyWith(
      hasUsagePermission: hasUsage,
      hasOverlayPermission: hasOverlay,
      hasAccessibilityPermission: hasAccessibility,
    );
  }

  Future<void> recheckPermissions() async {
    await _checkPermissions();
  }

  Future<void> requestUsagePermission() async {
    await _service.requestUsageStatsPermission();
    await _checkPermissions();
  }

  Future<void> requestOverlayPermission() async {
    await _service.requestOverlayPermission();
    await _checkPermissions();
  }

  Future<void> requestAccessibilityPermission() async {
    await _service.requestAccessibilityPermission();
    await _checkPermissions();
  }

  // ── Save personalization to Hive ──────────────────
  Future<void> savePersonalizationData() async {
    final box = Hive.box(HiveBoxNames.settings);
    await box.put('userName', state.userName ?? '');
    await box.put('dailyScreenTime', state.dailyScreenTime ?? '');
    await box.put('dailyHours', state.dailyHours ?? 3.5);
    await box.put('mainStruggle', state.mainStruggle ?? '');
    await box.put('goal', state.goal ?? '');
    await box.put('hearAboutUs', state.hearAboutUs ?? '');
  }

  // ── Complete ──────────────────────────────────────
  Future<void> completeOnboarding() async {
    await savePersonalizationData();
    final box = Hive.box(HiveBoxNames.settings);
    await box.put('onboardingComplete', true);
    state = state.copyWith(isComplete: true);
  }

  static bool isOnboardingComplete() {
    final box = Hive.box(HiveBoxNames.settings);
    return box.get('onboardingComplete', defaultValue: false) as bool;
  }
}