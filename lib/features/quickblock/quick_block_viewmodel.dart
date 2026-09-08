import 'package:flutter/cupertino.dart';
import 'package:pausenow/features/quickblock/widgets/quick_block_row.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:io';
import '../../data/repositoryImpl/QuickBlockRepoImpl.dart';
import '../../domain/platform/android_blocking_service.dart';
import '../../domain/platform/ios_blocking_service.dart';
import '../../providers/blocking_service_provider.dart';
import '../../providers/repository_providers.dart';
part 'quick_block_viewmodel.g.dart';

@riverpod
class QuickBlockViewModel extends _$QuickBlockViewModel {
  QuickBlockRepository get _repo => ref.read(quickBlockRepositoryProvider);

  @override
  Set<String> build() {
    return _repo.getAll().where((q) => !q.isExpired).map((q) => q.packageName).toSet();
  }

  Future<void> toggle(String packageName, {int? durationMinutes}) async {
    final isCurrentlyBlocked = state.contains(packageName);
    final blockingService = ref.read(blockingServiceProvider);

    if (isCurrentlyBlocked) {
      await _repo.unblock(packageName);
      if (blockingService is AndroidBlockingService) {
        await blockingService.setQuickBlocked(packageName, false);
      } else if (Platform.isIOS && blockingService is IOSBlockingService) {
        await blockingService.toggleQuickBlock(cardId: packageName, blocked: false);
      }
      state = {...state}..remove(packageName);
    } else {
      await _repo.block(packageName, durationMinutes: durationMinutes);
      if (blockingService is AndroidBlockingService) {
        await blockingService.setQuickBlocked(packageName, true);
      } else if (Platform.isIOS && blockingService is IOSBlockingService) {
        await blockingService.toggleQuickBlock(cardId: packageName, blocked: true);
      }
      state = {...state, packageName};
    }
  }

  Future<void> resetAll() async {
    final blockingService = ref.read(blockingServiceProvider);
    for (final app in quickBlockApps) {
      try {
        if (Platform.isIOS && blockingService is IOSBlockingService) {
          await blockingService.resetQuickBlockSelection(app.packageName);
        } else if (blockingService is AndroidBlockingService) {
          await blockingService.setQuickBlocked(app.packageName, false);
        }
        await _repo.unblock(app.packageName);
      } catch (e) {
        debugPrint('❌ resetAll failed for ${app.packageName}: $e');
      }
    }
    state = {};
  }

}