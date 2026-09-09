import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/lock_app_config.dart';
import '../../data/repositoryImpl/LockAppRepoImpl.dart';
import '../../domain/platform/android_blocking_service.dart';
import '../../domain/platform/ios_blocking_service.dart';
import '../../providers/blocking_service_provider.dart';
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
    await _repo.startPause(id, const Duration(minutes: 5)); // 👈 new — tracks the pause in Dart too
    loadConfigs();
    await _syncToNative();
  }

  Future<void> endPauseEarly(String id, String packageName) async {
    await _repo.clearPause(id);
    loadConfigs();
    final service = ref.read(blockingServiceProvider);
    if (service is AndroidBlockingService) {
      await service.endLockAppPauseEarly(packageName); // 👈 new native call
    }
  }


  Future<void> _syncToNative() async {
    if (Platform.isAndroid) {
      final configsJson = jsonEncode(state.configs.map((c) => {
        'id': c.id,
        'packageName': c.packageName,
        'appName': c.appName,
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
    } else if (Platform.isIOS) {
      final service = ref.read(blockingServiceProvider);
      if (service is IOSBlockingService) {
        await service.saveLockAppConfigIds(state.configs.map((c) => c.id).toList()); // 👈 new
        for (final config in state.configs) {
          if (config.isActive) {
            await service.applyLockAppShield(config.id);
          } else {
            await service.removeLockAppShield(config.id);
          }
        }
      }
    }
  }
}