import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/hivebox_names.dart';
import '../models/time_limit_config.dart';
import '../repositories/TimeLimitRepo.dart';


class TimeLimitRepositoryImpl implements TimeLimitRepository {

  Box<TimeLimitConfig> get _box =>
      Hive.box<TimeLimitConfig>(HiveBoxNames.timeLimitConfigs);

  @override
  List<TimeLimitConfig> getAllConfigs() {
    return _box.values.toList();
  }

  @override
  TimeLimitConfig? getConfig(String id) {
    return _box.get(id);
  }

  @override
  Future<void> saveConfig(TimeLimitConfig config) async {
    await _box.put(config.id, config);
  }

  @override
  Future<void> deleteConfig(String id) async {
    await _box.delete(id);
  }

  @override
  List<TimeLimitConfig> getConfigsContainingApp(String packageName) {
    return _box.values
        .where((config) => config.packageNames.contains(packageName))
        .toList();
  }
}