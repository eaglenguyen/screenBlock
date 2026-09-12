

class WheelState {
  final List<String> items;
  final bool isSpinning;
  final String? lastResult;
  final bool commitModeEnabled;
  final int spinsUsed;
  final DateTime? cooldownEndsAt;
  final String listName; // 👈 new

  static const maxSpinsBeforeCooldown = 3;
  static const cooldownDuration = Duration(minutes: 5);

  const WheelState({
    this.items = const [],
    this.isSpinning = false,
    this.lastResult,
    this.commitModeEnabled = false,
    this.spinsUsed = 0,
    this.cooldownEndsAt,
    this.listName = 'Entries', // 👈 new — same default as today
  });



  bool get isInCooldown =>
      cooldownEndsAt != null && DateTime.now().isBefore(cooldownEndsAt!);

  int get spinsRemaining => (maxSpinsBeforeCooldown - spinsUsed).clamp(0, maxSpinsBeforeCooldown);

  bool get canSpin => !commitModeEnabled || (!isInCooldown && spinsRemaining > 0);

  Duration get cooldownRemaining {
    if (cooldownEndsAt == null) return Duration.zero;
    final diff = cooldownEndsAt!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  WheelState copyWith({
    List<String>? items,
    bool? isSpinning,
    String? lastResult,
    bool clearLastResult = false,
    bool? commitModeEnabled,
    int? spinsUsed,
    DateTime? cooldownEndsAt,
    bool clearCooldown = false,
    String? listName, // 👈 new
  }) {
    return WheelState(
      items: items ?? this.items,
      isSpinning: isSpinning ?? this.isSpinning,
      lastResult: clearLastResult ? null : (lastResult ?? this.lastResult),
      commitModeEnabled: commitModeEnabled ?? this.commitModeEnabled,
      spinsUsed: spinsUsed ?? this.spinsUsed,
      cooldownEndsAt: clearCooldown ? null : (cooldownEndsAt ?? this.cooldownEndsAt),
      listName: listName ?? this.listName, // 👈 new
    );
  }
}
