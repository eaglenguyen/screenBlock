import 'package:flutter/foundation.dart';


enum BlockIntensity { soft, medium, hard }

@immutable
class TimerState {
  final String? packageName;
  final String? appName;
  final int selectedMinutes;
  final bool isSaving;
  final bool isSaved;
  final String? error;

  const TimerState({
    this.packageName,
    this.appName,
    this.selectedMinutes = 30,
    this.isSaving = false,
    this.isSaved = false,
    this.error,
  });


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
      isSaving: isSaving ?? this.isSaving,
      isSaved: isSaved ?? this.isSaved,
      error: error ?? this.error,
    );
  }
}