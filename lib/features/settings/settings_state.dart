import 'package:flutter/foundation.dart';

@immutable
class SettingsState {
  final bool hasUsagePermission;
  final bool hasOverlayPermission;
  final bool hasBatteryOptimization;
  final bool hasAccessibilityPermission;
  final bool isPremium;
  final String appVersion;
  final bool hasScreenTimePermission;


  const SettingsState({
    this.hasScreenTimePermission = false,
    this.hasUsagePermission = false,
    this.hasOverlayPermission = false,
    this.hasBatteryOptimization = false,
    this.hasAccessibilityPermission = false,
    this.isPremium = false,
    this.appVersion = '1.0.0',

  });

  SettingsState copyWith({
    bool? hasScreenTimePermission,
    bool? hasUsagePermission,
    bool? hasOverlayPermission,
    bool? hasBatteryOptimization,
    bool? hasAccessibilityPermission,
    bool? isPremium,
    String? appVersion,
  }) {
    return SettingsState(
      hasScreenTimePermission:
      hasScreenTimePermission ?? this.hasScreenTimePermission,
      hasUsagePermission:
      hasUsagePermission ?? this.hasUsagePermission,
      hasOverlayPermission:
      hasOverlayPermission ?? this.hasOverlayPermission,
      hasBatteryOptimization:
      hasBatteryOptimization ?? this.hasBatteryOptimization,
      hasAccessibilityPermission:
      hasAccessibilityPermission ?? this.hasAccessibilityPermission,
      isPremium: isPremium ?? this.isPremium,
      appVersion: appVersion ?? this.appVersion,
    );
  }
}