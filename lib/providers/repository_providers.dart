import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenblock/data/repositoryImpl/BlockingRepoImpl.dart';
import 'package:screenblock/data/repositoryImpl/UsageStreakRepo.dart';

import '../data/repositories/BlockingRepo.dart';


// interface bound to impl — swap impl here to move to Drift, Isar, or Supabase
final blockingRepositoryProvider = Provider<BlockingRepository>((ref) {
  return BlockingRepositoryImpl();
});

// no interface — direct impl
final usageRepositoryProvider = Provider<UsageStreakRepo>((ref) {
  return UsageStreakRepo();
});