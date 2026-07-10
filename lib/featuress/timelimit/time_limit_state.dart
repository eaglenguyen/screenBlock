import 'package:flutter/foundation.dart';
import '../../../data/models/time_limit_config.dart';

@immutable
class TimeLimitState {
  final List<TimeLimitConfig> configs;
  final bool isLoading;
  final String? error;

  const TimeLimitState({
    this.configs = const [],
    this.isLoading = false,
    this.error,
  });

  TimeLimitState copyWith({
    List<TimeLimitConfig>? configs,
    bool? isLoading,
    String? error,
  }) {
    return TimeLimitState(
      configs: configs ?? this.configs,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}