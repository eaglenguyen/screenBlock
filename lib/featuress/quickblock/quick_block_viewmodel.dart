import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositoryImpl/QuickBlockRepoImpl.dart';
import '../../domain/platform/android_blocking_service.dart';
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
      }
      // iOS: call setQuickBlocked equivalent with the saved token data
      state = {...state}..remove(packageName);
    } else {
      await _repo.block(packageName, durationMinutes: durationMinutes);
      if (blockingService is AndroidBlockingService) {
        await blockingService.setQuickBlocked(packageName, true);
      }
      // iOS: call setQuickBlocked equivalent with the saved token data
      state = {...state, packageName};
    }
  }
}