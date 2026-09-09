// lib/features/lockapp/lock_app_viewmodel.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/lock_app_config.dart';
import '../../data/repositoryImpl/LockAppRepoImpl.dart';
import '../../providers/repository_providers.dart';
import 'lock_app_state.dart';

part 'lock_app_viewmodel.g.dart';

@riverpod
class LockAppViewModel extends _$LockAppViewModel {
  LockAppRepository get _repo => ref.read(lockAppRepositoryProvider);

  @override
  LockAppState build() {
    Future.microtask(() => loadConfigs());
    return const LockAppState(isLoading: true);
  }

  void loadConfigs() {
    try {
      final configs = _repo.getAllConfigs();
      state = state.copyWith(configs: configs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> saveConfig({
    String? existingId,
    required String name,
    required String packageName,
    required String appName,
    required int maxUnlocks,
  }) async {
    final config = LockAppConfig(
      id: existingId ?? const Uuid().v4(),
      name: name,
      packageName: packageName,
      appName: appName,
      maxUnlocks: maxUnlocks,
      unlocksUsedToday: 0,
      lastResetDate: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _repo.saveConfig(config);
    loadConfigs(); // 👈 moved up — refreshes state.configs first
    await _syncToNative(); // 👈 now reads the correct, up-to-date state
  }

  Future<void> deleteConfig(String id) async {
    await _repo.deleteConfig(id);
    loadConfigs(); // 👈 before sync
    await _syncToNative();
  }

  Future<void> consumeUnlock(String id) async {
    await _repo.consumeUnlock(id);
    loadConfigs(); // 👈 before sync
    await _syncToNative();
  }

  Future<void> _syncToNative() async {
    if (!Platform.isAndroid) return;
    final configsJson = jsonEncode(state.configs.map((c) => {
      'id': c.id,
      'packageName': c.packageName,
      'appName': c.appName, // 👈 new
      'maxUnlocks': c.maxUnlocks,
      'unlocksUsedToday': c.unlocksUsedToday,
      'isActive': c.isActive,
    }).toList());
    try {
      await const MethodChannel('com.eagle.pausenow/accessibility')
          .invokeMethod('saveLockAppConfigs', {'configsJson': configsJson});
    } catch (e) {
      debugPrint('❌ saveLockAppConfigs error: $e');
    }
  }
}