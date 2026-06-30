import 'package:flutter/foundation.dart';

enum OnboardingStep {
  chat,
  personalization,
  calculation,
  demo,
  pricing,
  permissions,
  complete,
}



@immutable
class OnboardingState {
  final OnboardingStep currentStep;

  // personalization data
  final String? userName;
  final String? dailyScreenTime;
  final double? dailyHours; // calculated from dailyScreenTime
  final String? mainStruggle;
  final String? goal;
  final String? hearAboutUs;

  // permissions
  final bool hasUsagePermission;
  final bool hasOverlayPermission;
  final bool hasAccessibilityPermission;

  final bool isComplete;

  const OnboardingState({
    this.currentStep = OnboardingStep.chat,
    this.userName,
    this.dailyScreenTime,
    this.dailyHours,
    this.mainStruggle,
    this.goal,
    this.hearAboutUs,
    this.hasUsagePermission = false,
    this.hasOverlayPermission = false,
    this.hasAccessibilityPermission = false,
    this.isComplete = false,
  });

  // ── Calculated stats ──────────────────────────────
  double get monthlyHours => (dailyHours ?? 0) * 30;
  double get yearlyHours => (dailyHours ?? 0) * 365;
  double get daysPerYear => yearlyHours / 24;

  String get formattedDailyHours {
    final h = dailyHours ?? 0;
    if (h < 1) return '${(h * 60).round()} minutes';
    if (h == h.roundToDouble()) return '${h.round()} hours';
    return '${h.toString().replaceAll('.0', '')} hours';
  }

  String get formattedMonthlyHours =>
      '${monthlyHours.round()} hours';

  String get formattedDaysPerYear =>
      daysPerYear.toStringAsFixed(1);

  // ── Permissions ───────────────────────────────────
  bool get allPermissionsGranted =>
      hasUsagePermission &&
          hasOverlayPermission &&
          hasAccessibilityPermission;

  int get permissionsGranted {
    int count = 0;
    if (hasUsagePermission) count++;
    if (hasOverlayPermission) count++;
    if (hasAccessibilityPermission) count++;
    return count;
  }

  OnboardingState copyWith({
    OnboardingStep? currentStep,
    String? userName,
    String? dailyScreenTime,
    double? dailyHours,
    String? mainStruggle,
    String? goal,
    String? hearAboutUs,
    bool? hasUsagePermission,
    bool? hasOverlayPermission,
    bool? hasAccessibilityPermission,
    bool? isComplete,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      userName: userName ?? this.userName,
      dailyScreenTime: dailyScreenTime ?? this.dailyScreenTime,
      dailyHours: dailyHours ?? this.dailyHours,
      mainStruggle: mainStruggle ?? this.mainStruggle,
      goal: goal ?? this.goal,
      hearAboutUs: hearAboutUs ?? this.hearAboutUs,
      hasUsagePermission:
      hasUsagePermission ?? this.hasUsagePermission,
      hasOverlayPermission:
      hasOverlayPermission ?? this.hasOverlayPermission,
      hasAccessibilityPermission:
      hasAccessibilityPermission ?? this.hasAccessibilityPermission,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}