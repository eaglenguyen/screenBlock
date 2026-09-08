import 'package:hive/hive.dart';
import '../../core/constants/hivebox_names.dart';
import '../models/lock_app_config.dart';

class LockAppRepository {
  Box<LockAppConfig> get _box => Hive.box<LockAppConfig>(HiveBoxNames.lockApps);

  List<LockAppConfig> getAllConfigs() {
    _resetIfNewDay();
    return _box.values.toList();
  }

  LockAppConfig? getConfig(String id) => _box.get(id);

  Future<void> saveConfig(LockAppConfig config) async {
    await _box.put(config.id, config);
  }

  Future<void> deleteConfig(String id) async {
    await _box.delete(id);
  }

  // 👇 called whenever configs are read — resets any config whose lastResetDate isn't today
  void _resetIfNewDay() {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    for (final config in _box.values) {
      final resetKey = DateTime(
        config.lastResetDate.year,
        config.lastResetDate.month,
        config.lastResetDate.day,
      );
      if (resetKey != todayKey) {
        config.unlocksUsedToday = 0;
        config.lastResetDate = today;
        config.save();
      }
    }
  }

  Future<void> consumeUnlock(String id) async {
    final config = _box.get(id);
    if (config == null) return;
    config.unlocksUsedToday += 1;
    await config.save();
  }
}