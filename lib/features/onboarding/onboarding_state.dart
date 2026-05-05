import 'package:flutter/foundation.dart';

enum OnboardingStep {
  splash,
  chat,
  hookBadNews,
  hookGoodNews,
  permissions,
  complete,
}

@immutable
class OnboardingState {
  final OnboardingStep currentStep;
  final String? screenTimeRange;  // from chat question 1
  final String? ageRange;         // from chat question 2
  final String? feelingAboutUsage;// from chat question 3
  final String? goal;             // from chat question 4
  final bool hasUsagePermission;
  final bool hasOverlayPermission;
  final bool isComplete;

  const OnboardingState({
    this.currentStep = OnboardingStep.splash,
    this.screenTimeRange,
    this.ageRange,
    this.feelingAboutUsage,
    this.goal,
    this.hasUsagePermission = false,
    this.hasOverlayPermission = false,
    this.isComplete = false,
  });

  // how many permissions are granted out of 2
  int get permissionsGranted {
    int count = 0;
    if (hasUsagePermission) count++;
    if (hasOverlayPermission) count++;
    return count;
  }

  bool get allPermissionsGranted =>
      hasUsagePermission && hasOverlayPermission;

  OnboardingState copyWith({
    OnboardingStep? currentStep,
    String? screenTimeRange,
    String? ageRange,
    String? feelingAboutUsage,
    String? goal,
    bool? hasUsagePermission,
    bool? hasOverlayPermission,
    bool? isComplete,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      screenTimeRange: screenTimeRange ?? this.screenTimeRange,
      ageRange: ageRange ?? this.ageRange,
      feelingAboutUsage: feelingAboutUsage ?? this.feelingAboutUsage,
      goal: goal ?? this.goal,
      hasUsagePermission:
      hasUsagePermission ?? this.hasUsagePermission,
      hasOverlayPermission:
      hasOverlayPermission ?? this.hasOverlayPermission,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}