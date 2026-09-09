// lib/features/wheel/wheel_state.dart
class WheelState {
  final List<String> items;
  final bool isSpinning;
  final String? lastResult;

  const WheelState({
    this.items = const [],
    this.isSpinning = false,
    this.lastResult,
  });

  WheelState copyWith({
    List<String>? items,
    bool? isSpinning,
    String? lastResult,
    bool clearLastResult = false,
  }) {
    return WheelState(
      items: items ?? this.items,
      isSpinning: isSpinning ?? this.isSpinning,
      lastResult: clearLastResult ? null : (lastResult ?? this.lastResult),
    );
  }
}