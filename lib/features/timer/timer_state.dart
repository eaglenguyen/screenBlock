import 'package:flutter/foundation.dart';
import '../../../data/models/timer_config.dart';
import '../../../core/constants/app_constants.dart';

enum BlockIntensity { soft, medium, hard }

@immutable
class TimerState {
  final String? packageName;
  final String? appName;
  final int selectedMinutes;
  final BlockIntensity intensity;
  final bool isSaving;
  final bool isSaved;
  final String? error;

  const TimerState({
    this.packageName,
    this.appName,
    this.selectedMinutes = 30,
    this.intensity = BlockIntensity.medium,
    this.isSaving = false,
    this.isSaved = false,
    this.error,
  });

  // convenience getter
  String get intensityString {
    switch (intensity) {
      case BlockIntensity.soft:
        return AppConstants.softBlock;
      case BlockIntensity.medium:
        return AppConstants.mediumBlock;
      case BlockIntensity.hard:
        return AppConstants.hardBlock;
    }
  }

  TimerState copyWith({
    String? packageName,
    String? appName,
    int? selectedMinutes,
    BlockIntensity? intensity,
    bool? isSaving,
    bool? isSaved,
    String? error,
  }) {
    return TimerState(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      selectedMinutes: selectedMinutes ?? this.selectedMinutes,
      intensity: intensity ?? this.intensity,
      isSaving: isSaving ?? this.isSaving,
      isSaved: isSaved ?? this.isSaved,
      error: error ?? this.error,
    );
  }
}