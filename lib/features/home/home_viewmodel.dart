import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:screenblock/data/repositoryImpl/UsageStreakRepo.dart';

import '../../../domain/platform/blocking_service.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/blocking_service_provider.dart';
import '../../data/models/timer_config.dart';
import '../../data/repositories/BlockingRepo.dart';
import 'home_state.dart';

part 'home_viewmodel.g.dart';


@riverpod
class HomeViewModel extends _$HomeViewModel {

  StreamSubscription? _usageSubscription;
  StreamSubscription? _overlaySubscription;
  bool _streamsInitialized = false;

  @override
  HomeState build() {
    // only cleanup logic lives here
    ref.onDispose(() {
      _usageSubscription?.cancel();
      _overlaySubscription?.cancel();
      _streamsInitialized = false;

    });

    return const HomeState(isLoading: true);
  }

  // ── Called once from HomeScreen.initState ────────
  void init() {
    _setupStreams();
    loadTrackedApps();
  }

  // ── Stream setup ─────────────────────────────────
  void _setupStreams() {
    if (_streamsInitialized) return;
    _streamsInitialized = true;

    // cancel any existing before creating new
    _usageSubscription?.cancel();
    _overlaySubscription?.cancel();

    _usageSubscription = _blockingService.usageEvents.listen((event) {
      switch (event.type) {
        case AppEventType.timerExpired:
          state = state.copyWith(
            error: 'timer_expired:${event.packageName}',
          );
          break;
        case AppEventType.timerWarning:
          state = state.copyWith(
            error: 'timer_warning:${event.packageName}',
          );
          break;
        default:
          break;
      }
    });
    // overlay listener is a single-subscription stream
    // only subscribe if not already subscribed
    if (_overlaySubscription == null) {
      try {
        _overlaySubscription =
            FlutterOverlayWindow.overlayListener.listen((data) {
              if (data == 'block_for_day') {
                // TODO: block the app
              }
            });
      } catch (e) {
        debugPrint('❌ overlay listener already subscribed: $e');
      }
    }
  }

  // ── Getters ──────────────────────────────────────
  BlockingRepository get _blockingRepo =>
      ref.read(blockingRepositoryProvider);

  UsageStreakRepo get _usageRepo =>
      ref.read(usageRepositoryProvider);

  BlockingService get _blockingService =>
      ref.read(blockingServiceProvider);

  // ── Load ─────────────────────────────────────────
  void loadTrackedApps() {
    try {
      final timers = _blockingRepo.getAllTimers();
      final streak = _usageRepo.getStreak();
      state = state.copyWith(
        trackedApps: timers,
        streak: streak,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // ── Add / remove ─────────────────────────────────
  Future<void> addTrackedApp(TimerConfig config) async {
    try {
      if (_blockingRepo.hasReachedFreeLimit()) {
        state = state.copyWith(error: 'free_limit_reached');
        return;
      }
      await _blockingRepo.saveTimer(config);
      await _blockingService.startMonitoring(
        config.packageName,
        config.limitMinutes,
      );
      loadTrackedApps();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> removeTrackedApp(String packageName) async {
    try {
      await _blockingRepo.deleteTimer(packageName);
      await _blockingService.stopMonitoring(packageName);
      loadTrackedApps();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ── Block / unblock ──────────────────────────────
  Future<void> blockAppForDay(String packageName) async {
    try {
      await _blockingRepo.blockApp(packageName);
      await _blockingService.blockApp(packageName);
      loadTrackedApps();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> unblockApp(String packageName) async {
    try {
      await _blockingRepo.unblockApp(packageName);
      await _blockingService.unblockApp(packageName);
      loadTrackedApps();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}