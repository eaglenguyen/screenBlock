import '../models/time_limit_config.dart';

abstract class TimeLimitRepository {
  List<TimeLimitConfig> getAllConfigs();
  TimeLimitConfig? getConfig(String id);
  Future<void> saveConfig(TimeLimitConfig config);
  Future<void> deleteConfig(String id);

  /// Returns all configs that include this package name — used both for
  /// enforcement (checking usage against every config touching this app)
  /// and for conflict-checking during schedule/config creation.
  List<TimeLimitConfig> getConfigsContainingApp(String packageName);
}