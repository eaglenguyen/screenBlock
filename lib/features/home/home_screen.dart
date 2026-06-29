import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pausenow/features/home/timer/break_sheet.dart';
import 'package:pausenow/features/home/cards/countdown_card.dart';
import 'package:pausenow/features/home/cards/active_blocking_card.dart';
import 'package:pausenow/features/home/timer/pomodoro_sheet.dart';
import 'package:pausenow/features/home/widgets/app_list_sheet.dart';
import 'package:pausenow/features/home/widgets/block_mode_sheet.dart';
import 'package:pausenow/features/home/widgets/home_header.dart';
import 'package:pausenow/features/home/timer/timer_card.dart';
import 'package:pausenow/features/home/timer/timer_picker_sheet.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/permission_dialogs.dart';
import '../../providers/blocking_service_provider.dart';
import '../../services/xp_animation.dart';
import '../onboarding/manual_blocking_tutorial.dart';
import 'cards/claim_xp_card.dart';
import 'cards/session_completed_card.dart';
import 'home_state.dart';
import 'home_viewmodel.dart';

final GlobalKey _xpBadgeKey = GlobalKey();


class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  bool _hasShownXpAnimation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeViewModelProvider.notifier).init();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(homeViewModelProvider.notifier).onAppResumed();
      ref.read(blockingServiceProvider).resetOverlayState();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeViewModelProvider);

    ref.listen(homeViewModelProvider, (previous, next) {
      if (previous?.phase == BlockingPhase.claimXp &&
          next.phase == BlockingPhase.idle &&
          !_hasShownXpAnimation) {

        _hasShownXpAnimation = true;
        final overlay = Overlay.of(context);
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            XpAnimation.instance.showXpGain(
              overlay: overlay,
              xpBadgeKey: _xpBadgeKey,
              xpAmount: previous?.xpEarned ?? 0,
            );
            Future.delayed(const Duration(milliseconds: 1000), () {
              _hasShownXpAnimation = false;
            });
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Column(
        children: [
          HomeHeader(
            state: state,
            xpBadgeKey: _xpBadgeKey,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 100),
              child: Column(
                children: [
                  // ── Schedule banner ─────────────────────────
                  if (state.isScheduleActive)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: state.isSchedulePaused
                            ? Colors.orange.withValues(alpha: 0.1)
                            : AppColors.error(context).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: state.isSchedulePaused
                              ? Colors.orange.withValues(alpha: 0.3)
                              : AppColors.error(context).withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            state.isSchedulePaused
                                ? Icons.pause_circle_outline_rounded
                                : Icons.block_rounded,
                            color: state.isSchedulePaused
                                ? Colors.orange
                                : AppColors.error(context),
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.isSchedulePaused
                                  ? 'Schedule paused — resumes in ${state.formattedPauseRemaining}'
                                  : 'To use Manual Block, please disable the schedule session!',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: state.isSchedulePaused
                                    ? Colors.orange
                                    : AppColors.error(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // ── Phase cards ──────────────────────────────
                  switch (state.phase) {
                    // Idle
                    BlockingPhase.idle => TimerCard(
                      onBlockNow: _onBlockNowTapped,
                      onSelectorTapped: _onSelectorTapped,
                      onBlockModeTapped: _onBlockModeTapped,
                      onTimerTapped: _onTimerTapped,
                      blockingType: state.blockingType,
                      selectedMinutes: state.selectedMinutes,
                      blockedTime: state.formattedBlockedTime,
                      shouldAnimate: state.shouldAnimateBlockedTime,
                      isScheduleActive: state.isScheduleActive,
                      onPomodoroTapped: _onPomodoroTapped,
                      isPomodoroMode: state.pomodoroConfig.isPomodoroMode,
                      onTutorialTap: () {
                        showGeneralDialog(
                          context: context,
                          barrierDismissible: false,
                          barrierColor: Colors.black,
                          transitionDuration: const Duration(milliseconds: 300),
                          transitionBuilder: (_, anim, __, child) => FadeTransition(
                            opacity: anim,
                            child: child,
                          ),
                            pageBuilder: (dialogContext, __, ___) => Scaffold( // 👈 wrap in Scaffold
                              backgroundColor: const Color(0xFF16162A),
                              body: ManualBlockingTutorial(
                                onComplete: () => Navigator.of(dialogContext).pop(),
                                showSkip: true,
                              ),
                            ),
                        );
                      },
                      onAnimationStarted: () => ref
                          .read(homeViewModelProvider.notifier)
                          .resetAnimateBlockedTime(),
                    ),
                  // Countdown
                    BlockingPhase.countdown => CountdownCard(
                      count: state.remainingSeconds,
                      onCancel: _onCancelCountdown,
                    ),
                  // Active
                    BlockingPhase.active || BlockingPhase.onBreak =>
                        ActiveBlockingCard(
                          state: state,
                          onTakeBreak: _onTakeBreak,
                          onGiveUp: _onGiveUp,
                          onEndBreak: () => _showEndBreakConfirm(),
                          onBlockListTapped: _onBlockListTapped,
                        ),
                  // Completed
                    BlockingPhase.completed => SessionCompletedCard(
                      selectedMinutes: state.selectedMinutes,
                      xpEarned: state.xpEarned,
                      onFinish: () => ref
                          .read(homeViewModelProvider.notifier)
                          .finishAndUnblock(),
                    ),
                  // Claim XP
                    BlockingPhase.claimXp => ClaimXpCard(
                      xpEarned: state.xpEarned,
                      sessionMinutes: state.selectedMinutes,
                      todayBlocked: state.formattedBlockedTime,
                      totalXp: state.totalXp,
                      onClaim: () => ref
                          .read(homeViewModelProvider.notifier)
                          .claimXp(),
                    ),
                  },

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }

  void _onPomodoroTapped() {
    PomodoroSheet.show(
      context,
      config: ref.read(homeViewModelProvider).pomodoroConfig,
      onSave: (config) {
        ref.read(homeViewModelProvider.notifier).setPomodoroConfig(config);
      },
    );
  }

  void _onBlockNowTapped() async {
    final state = ref.read(homeViewModelProvider);
    final notifier = ref.read(homeViewModelProvider.notifier);
    final service = ref.read(blockingServiceProvider);

    if (state.phase == BlockingPhase.idle) {
      final hasApps = state.blockingType == AppConstants.blockingTypeSpecificApps
          ? state.blockedApps.isNotEmpty
          : state.allowedApps.isNotEmpty;

      if (!hasApps) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.backgroundCard(context),
            content: Text(
              state.blockingType == AppConstants.blockingTypeSpecificApps
                  ? 'Add apps to block first'
                  : 'Add apps to allow first',
              style: TextStyle(color: AppColors.textPrimary(context)),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }

      if (Platform.isAndroid) {
        // check accessibility
        final hasAccessibility = await service.hasAccessibilityPermission();
        if (!hasAccessibility) {
          if (!context.mounted) return;
          final openSettings = await showAccessibilityDialog(context);
          if (openSettings && context.mounted) {
            await service.requestAccessibilityPermission();
          }
          return;
        }

        // check overlay
        final hasOverlay = await service.hasOverlayPermission();
        if (!hasOverlay) {
          if (!context.mounted) return;
          await service.requestOverlayPermission();
          return;
        }
      }

      if (!context.mounted) return;
      notifier.startBlocking();
    }
  }

  void _onSelectorTapped(String type) {}

  void _onBlockModeTapped() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => const BlockModeSheet(),
    );
  }

  void _onTimerTapped() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => TimerPickerSheet(
        selectedMinutes:
        ref.read(homeViewModelProvider).selectedMinutes,
        onSave: (minutes) => ref
            .read(homeViewModelProvider.notifier)
            .setSelectedMinutes(minutes),
      ),
    );
  }

  void _onCancelCountdown() {
    ref.read(homeViewModelProvider.notifier).cancelCountdown();
  }

  void _onTakeBreak() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => BreakSheet(
        onStartBreak: (minutes) {
          ref.read(homeViewModelProvider.notifier).startBreak(minutes);
        },
      ),
    );
  }

  void _onGiveUp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Give up?',
          style: AppTextStyles.headlineSmall,
          textAlign: TextAlign.center,
        ),
        content: Text(
          'If you give up, no ⭐️\'s',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(homeViewModelProvider.notifier).giveUp();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error(context),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const StadiumBorder(),
              ),
              child: const Text('Yes, give up'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary(context),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const StadiumBorder(),
                side:  BorderSide(color: AppColors.border(context)),
              ),
              child: const Text("Don't give up"),
            ),
          ),
        ],
      ),
    );
  }

  void _onBlockListTapped() {
    final state = ref.read(homeViewModelProvider);
    final isAllApps =
        state.blockingType == AppConstants.blockingTypeAllApps;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => AppListSheet(
        isBlockList: !isAllApps,
        initialApps:
        isAllApps ? state.allowedApps : state.blockedApps,
        onSave: (apps) {
          final notifier = ref.read(homeViewModelProvider.notifier);
          if (isAllApps) {
            notifier.setAllowedApps(apps);
          } else {
            notifier.setBlockedApps(apps);
          }
        },
      ),
    );
  }
  // Bottom sheet for resume pause
  void _showEndBreakConfirm() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
          24, 20, 24,
          MediaQuery.of(ctx).padding.bottom + 100,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E35),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Blocking Paused',
              style: AppTextStyles.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Your break is ongoing.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ref.read(homeViewModelProvider.notifier).endBreak();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEDB82A),
                  foregroundColor: const Color(0xFF1A1208),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('End Break'),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}