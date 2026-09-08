import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pausenow/data/repositoryImpl/BlockingRepoImpl.dart';
import 'package:pausenow/data/repositoryImpl/UsageStreakRepo.dart';

import '../data/repositories/BlockingRepo.dart';
import '../data/repositories/ScheduleRepo.dart';
import '../data/repositories/SettingsRepo.dart';
import '../data/repositories/TimeLimitRepo.dart';
import '../data/repositoryImpl/LockAppRepoImpl.dart';
import '../data/repositoryImpl/QuickBlockRepoImpl.dart';
import '../data/repositoryImpl/ScheduleRepoImpl.dart';
import '../data/repositoryImpl/SettingsRepoImpl.dart';
import '../data/repositoryImpl/TimeLimitRepoImpl.dart';
import '../data/repositoryImpl/block_session_repository.dart';


// interface bound to impl — swap impl here to move to Drift, Isar, or Supabase
final blockingRepositoryProvider = Provider<BlockingRepository>((ref) {
  return BlockingRepositoryImpl();
});

// no interface — direct impl
final usageRepositoryProvider = Provider<UsageStreakRepo>((ref) {
  return UsageStreakRepo();
});

final blockSessionRepositoryProvider =
    Provider<BlockSessionRepository>((ref) {
      return BlockSessionRepository();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl();
});

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepositoryImpl();
});

final timeLimitRepositoryProvider = Provider<TimeLimitRepository>((ref) {
  return TimeLimitRepositoryImpl();
});


final quickBlockRepositoryProvider = Provider<QuickBlockRepository>((ref) {
  return QuickBlockRepository();
});

final lockAppRepositoryProvider = Provider<LockAppRepository>((ref) {
  return LockAppRepository();
});