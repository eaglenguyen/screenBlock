class AppLimitConflict {
  final String name;
  final String source; // 'schedule' or 'time_limit'

  const AppLimitConflict({
    required this.name,
    required this.source,
  });
}