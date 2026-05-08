import 'package:flutter/foundation.dart';

@immutable
class SettingsState {
  final bool hasUsagePermission;
  final bool hasOverlayPermission;
  final bool hasBatteryOptimization;
  final bool isPremium;
  final String appVersion;

  const SettingsState({
    this.hasUsagePermission = false,
    this.hasOverlayPermission = false,
    this.hasBatteryOptimization = false,
    this.isPremium = false,
    this.appVersion = '1.0.0',
  });

  SettingsState copyWith({
    bool? hasUsagePermission,
    bool? hasOverlayPermission,
    bool? hasBatteryOptimization,
    bool? isPremium,
    String? appVersion,
  }) {
    return SettingsState(
      hasUsagePermission:
      hasUsagePermission ?? this.hasUsagePermission,
      hasOverlayPermission:
      hasOverlayPermission ?? this.hasOverlayPermission,
      hasBatteryOptimization:
      hasBatteryOptimization ?? this.hasBatteryOptimization,
      isPremium: isPremium ?? this.isPremium,
      appVersion: appVersion ?? this.appVersion,
    );
  }
}