// lib/data/repositoryImpl/quick_block_repository.dart
import 'package:hive/hive.dart';
import '../../core/constants/hivebox_names.dart';
import '../models/quick_block.dart';

class QuickBlockRepository {
  Box<QuickBlock> get _box => Hive.box<QuickBlock>(HiveBoxNames.quickBlocks);

  List<QuickBlock> getAll() => _box.values.toList();

  bool isBlocked(String packageName) =>
      _box.values.any((q) => q.packageName == packageName && !q.isExpired);

  Future<void> block(String packageName, {int? durationMinutes}) async {
    final existing = _box.values.where((q) => q.packageName == packageName).toList();
    for (final e in existing) {
      await e.delete();
    }
    await _box.add(QuickBlock(
      packageName: packageName,
      durationMinutes: durationMinutes,
      startedAt: DateTime.now(),
    ));
  }

  Future<void> unblock(String packageName) async {
    final matches = _box.values.where((q) => q.packageName == packageName).toList();
    for (final m in matches) {
      await m.delete();
    }
  }

  Future<void> removeExpired() async {
    final expired = _box.values.where((q) => q.isExpired).toList();
    for (final e in expired) {
      await e.delete();
    }
  }
}