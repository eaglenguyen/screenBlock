import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/platform/blocking_service.dart';
import '../../../providers/blocking_service_provider.dart';
import 'onboarding_state.dart';

part 'onboarding_viewmodel.g.dart';

@riverpod
class OnboardingViewModel extends _$OnboardingViewModel {

  static const String _onboardingCompleteKey = 'onboarding_complete';

  @override
  OnboardingState build() {
    _checkPermissions();
    return const OnboardingState();
  }

  BlockingService get _service =>
      ref.read(blockingServiceProvider);

  // ── Navigation ──────────────────────────────────
  void nextStep() {
    final steps = OnboardingStep.values;
    final currentIndex = steps.indexOf(state.currentStep);
    if (currentIndex < steps.length - 1) {
      state = state.copyWith(
        currentStep: steps[currentIndex + 1],
      );
    }
  }

  void goToStep(OnboardingStep step) {
    state = state.copyWith(currentStep: step);
  }

  // ── Chat answers ────────────────────────────────
  void setScreenTimeRange(String range) {
    state = state.copyWith(screenTimeRange: range);
  }

  void setAgeRange(String range) {
    state = state.copyWith(ageRange: range);
  }

  void setFeelingAboutUsage(String feeling) {
    state = state.copyWith(feelingAboutUsage: feeling);
  }

  void setGoal(String goal) {
    state = state.copyWith(goal: goal);
  }

  // ── Permissions ─────────────────────────────────
  Future<void> _checkPermissions() async {
    final hasUsage = await _service.hasUsageStatsPermission();
    final hasOverlay = await _service.hasOverlayPermission();
    state = state.copyWith(
      hasUsagePermission: hasUsage,
      hasOverlayPermission: hasOverlay,
    );
  }

  Future<void> requestUsagePermission() async {
    await _service.requestUsageStatsPermission();
    // re-check after user returns from settings
    await _checkPermissions();
  }

  Future<void> requestOverlayPermission() async {
    await _service.requestOverlayPermission();
    await _checkPermissions();
  }

  // ── Complete ─────────────────────────────────────
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, true);
    state = state.copyWith(isComplete: true);
  }

  static Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }
}