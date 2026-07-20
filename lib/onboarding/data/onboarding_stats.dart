class OnboardingStatsData {
  final int age;
  final double hoursPerDay;

  const OnboardingStatsData({
    required this.age,
    required this.hoursPerDay,
  });

  // years lost to phone over lifetime (0 → 80)
  double get yearsLostTotal {
    final hoursPerYear = hoursPerDay * 365;
    final yearsLost = (hoursPerYear * 80) / 8760;
    return yearsLost;
  }

  // years lost already (0 → current age)
  double get yearsLostAlready {
    final hoursPerYear = hoursPerDay * 365;
    return (hoursPerYear * age) / 8760;
  }

  // years that will still be lost (current age → 80)
  double get yearsLostRemaining {
    return yearsLostTotal - yearsLostAlready;
  }

  // how many years you save if you cut usage in half
  double get yearsSavedIfHalved {
    final reducedHours = hoursPerDay / 2;
    final hoursPerYear = reducedHours * 365;
    return (hoursPerYear * (80 - age)) / 8760;
  }

  String formatYears(double years) {
    if (years < 1) {
      final months = (years * 12).round();
      return months == 1 ? '1 month' : '$months months';
    }
    final rounded = years.round();
    return rounded == 1 ? '1 year' : '$rounded years';
  }
}