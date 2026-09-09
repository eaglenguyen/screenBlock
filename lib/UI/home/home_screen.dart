import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pausenow/UI/home/timer/break_sheet.dart';
import 'package:pausenow/UI/home/timer/pomodoro_sheet.dart';
import 'package:pausenow/UI/home/timer/timer_card.dart';
import 'package:pausenow/UI/home/timer/timer_picker_sheet.dart';
import 'package:pausenow/UI/home/widgets/app_list_sheet.dart';
import 'package:pausenow/UI/home/widgets/block_mode_sheet.dart';
import 'package:pausenow/UI/home/widgets/home_header.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/permission_dialogs.dart';
import '../../domain/platform/android_blocking_service.dart';
import '../../features/lockapp/lock_app_viewmodel.dart';
import '../../features/lockapp/widget/lock_app_confirm_sheet.dart';
import '../../features/wheel/widgets/spin_wheel_card.dart';
import '../../onboarding/manual_blocking_tutorial.dart';
import '../../providers/blocking_service_provider.dart';
import '../settings/settings_viewmodel.dart';
import 'cards/active_blocking_card.dart';
import 'cards/break_confirmation_card.dart';
import 'cards/countdown_card.dart';
import 'widgets/xp_animation.dart';
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

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _hasShownXpAnimation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeViewModelProvider.notifier).init();
    });
  }

  @override
  void dispose() {
    super.dispose();
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

              ref.read(homeViewModelProvider.notifier).requestReviewOnFirstClaim();

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
              if (state.isScheduleActive || state.isAppLimitActiveToday)
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
              if (state.phase == BlockingPhase.active || state.phase == BlockingPhase.onBreak)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom -
                        150,
                  ),
                  child: Center(
                    child: ActiveBlockingCard(
                      state: state,
                      onTakeBreak: _onTakeBreak,
                      onGiveUp: _onGiveUp,
                      onEndBreak: () => _showEndBreakConfirm(),
                      onBlockListTapped: _onBlockListTapped,
                      isPomodoroMode: state.pomodoroConfig.isPomodoroMode,
                      pomodoroRound: state.pomodoroRoundCount,
                      isPaused: state.isPaused,
                      onPauseToggle: () => ref.read(homeViewModelProvider.notifier).togglePause(),
                      onRestart: () => ref.read(homeViewModelProvider.notifier).restartRound(),
                      onSkipRound: () => ref.read(homeViewModelProvider.notifier).skipRound(),
                      isHardMode: ref.watch(settingsViewModelProvider).hardModeEnabled,
                    ),
                  ),
                )
              else
                switch (state.phase) {
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
                    isAppLimitActiveToday: state.isAppLimitActiveToday,
                    onPomodoroTapped: _onPomodoroTapped,
                    isPomodoroMode: state.pomodoroConfig.isPomodoroMode,
                    pomodoroRestMinutes: state.pomodoroConfig.shortBreakMinutes,
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
                        pageBuilder: (dialogContext, __, ___) => Scaffold(
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
                  BlockingPhase.countdown => CountdownCard(
                    count: state.remainingSeconds,
                    onCancel: _onCancelCountdown,
                  ),
                  BlockingPhase.completed => SessionCompletedCard(
                    selectedMinutes: state.selectedMinutes,
                    xpEarned: state.xpEarned,
                    onFinish: () => ref
                        .read(homeViewModelProvider.notifier)
                        .finishAndUnblock(),
                  ),
                  BlockingPhase.awaitingBreakConfirmation => BreakConfirmationCard(
                    onYes: () => ref.read(homeViewModelProvider.notifier).confirmStartBreak(),
                    onNo: () => ref.read(homeViewModelProvider.notifier).declineStartBreak(),
                  ),
                  BlockingPhase.claimXp => ClaimXpCard(
                    xpEarned: state.xpEarned,
                    sessionMinutes: state.selectedMinutes,
                    todayBlocked: state.formattedBlockedTime,
                    totalXp: state.totalXp,
                    onClaim: () => ref
                        .read(homeViewModelProvider.notifier)
                        .claimXp(),
                  ),
                  _ => const SizedBox.shrink(),
                },

              const SizedBox(height: 12),
              const SpinWheelCard(),
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

      await checkAccessibilityAndProceed(context, ref, () async {
        if (Platform.isAndroid) {
          final hasOverlay = await service.hasOverlayPermission();
          if (!hasOverlay) {
            await service.requestOverlayPermission();
            return;
          }
        }
        notifier.startBlocking();
      });
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

  Future<void> _onTimerTapped() async {
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => TimerPickerSheet(
        selectedMinutes: ref.read(homeViewModelProvider).selectedMinutes,
      ),
    );
    if (result != null) {
      ref.read(homeViewModelProvider.notifier).setSelectedMinutes(result);
    }
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
  void _showEndBreakConfirm() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
          24, 20, 24,
          MediaQuery.of(ctx).padding.bottom + 100,
        ),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppColors.border(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Blocking Paused',
              style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary(context)),
            ),
            const SizedBox(height: 8),
            Text(
              'Your break is ongoing.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary(context),
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
                  backgroundColor: AppColors.warning(context),
                  foregroundColor: AppColors.warningLight(context),
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