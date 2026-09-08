// lib/features/lockapp/lock_app_state.dart
import '../../data/models/lock_app_config.dart';

class LockAppState {
  final List<LockAppConfig> configs;
  final bool isLoading;
  final String? error;

  const LockAppState({
    this.configs = const [],
    this.isLoading = false,
    this.error,
  });

  LockAppState copyWith({
    List<LockAppConfig>? configs,
    bool? isLoading,
    String? error,
  }) {
    return LockAppState(
      configs: configs ?? this.configs,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}