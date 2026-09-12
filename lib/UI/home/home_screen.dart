import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:pausenow/UI/home/timer/break_sheet.dart';
import 'package:pausenow/UI/home/timer/pomodoro_sheet.dart';
import 'package:pausenow/UI/home/timer/timer_card.dart';
import 'package:pausenow/UI/home/timer/timer_picker_sheet.dart';
import 'package:pausenow/UI/home/widgets/app_list_sheet.dart';
import 'package:pausenow/UI/home/widgets/block_mode_sheet.dart';
import 'package:pausenow/UI/home/widgets/give_up_dialog.dart';
import 'package:pausenow/UI/home/widgets/home_header.dart';
import 'package:pausenow/UI/home/widgets/home_tutorial_overlay.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/hivebox_names.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/permission_dialogs.dart';
import '../../features/quickblock/widgets/quick_block_row.dart';
import '../../onboarding/manual_blocking_tutorial.dart';
import '../../providers/blocking_service_provider.dart';
import '../../providers/home_ui_state.dart';
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
  bool _quickBlocksCollapsing = false;
  Key? _quickBlocksKey;

  // 👇 new — tutorial target keys
  final GlobalKey _blockModeKey = GlobalKey();
  final GlobalKey _timerModeKey = GlobalKey();
  final GlobalKey _startButtonKey = GlobalKey();
  bool _hasCheckedTutorial = false; // 👈 new — guards against re-triggering mid-session
  bool _isBreakRelatedSheetOpen = false; // 👈 new — covers both BreakSheet and the End Break confirm sheet


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeViewModelProvider.notifier).init();
    });
  }

  // 👇 shared — both the auto-trigger and the "?" tap call this
  void _showHomeTutorial() {
    HomeTutorialOverlay.show(
      context,
      steps: [
        HomeTutorialStep(title: '1) Add apps',  targetKey: _blockModeKey),
        HomeTutorialStep(title: '2) Choose session time', targetKey: _timerModeKey),
        HomeTutorialStep(title: '3) Block your apps!', targetKey: _startButtonKey),
      ],
      onComplete: () {},
    );
  }


  void _maybeShowHomeTutorial(HomeState state) {
    if (_hasCheckedTutorial) return;
    if (state.phase != BlockingPhase.idle) return;
    _hasCheckedTutorial = true;

    final box = Hive.box(HiveBoxNames.settings);
    final seen = box.get('seenHomeTutorial', defaultValue: false) as bool;
    if (seen) return; // 👈 auto-trigger only fires once ever — gated by the flag

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      HomeTutorialOverlay.show(
        context,
        steps: [
          HomeTutorialStep(title: '1) Add apps',  targetKey: _blockModeKey),
          HomeTutorialStep(title: '2) Choose session time', targetKey: _timerModeKey),
          HomeTutorialStep(title: '3) Block your apps!', targetKey: _startButtonKey),
        ],
        onComplete: () => box.put('seenHomeTutorial', true), // 👈 marks seen only on the automatic first-time play
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeViewModelProvider);
    final quickBlocksExpanded = ref.watch(quickBlocksExpandedProvider); // 👈 new

    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowHomeTutorial(state)); // 👈 new

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
      // 👇 new — dismiss Take a Break / End Break sheets if the session wraps up while one is open
      final justCompleted = (next.phase == BlockingPhase.completed || next.phase == BlockingPhase.claimXp)
          && previous?.phase != next.phase;
      if (justCompleted && _isBreakRelatedSheetOpen) {
        Navigator.of(context, rootNavigator: true).popUntil((route) => route is! PopupRoute);
        _isBreakRelatedSheetOpen = false;
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
                    blockModeKey: _blockModeKey, // 👈 new
                    timerModeKey: _timerModeKey, // 👈 new
                    startButtonKey: _startButtonKey, // 👈 new
                    onTutorialTap: () {
                      _showHomeTutorial();
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

              const SizedBox(height: 16),
              if (state.phase == BlockingPhase.idle) ...[ // 👈 new — only shown when idle, hidden for every other phase
                GestureDetector(
                  onTap: () async {
                    if (quickBlocksExpanded) {
                      setState(() => _quickBlocksCollapsing = true);
                      await Future.delayed(const Duration(milliseconds: 900));
                      ref.read(quickBlocksExpandedProvider.notifier).set(false);
                      setState(() => _quickBlocksCollapsing = false);
                    } else {
                      ref.read(quickBlocksExpandedProvider.notifier).set(true);
                      setState(() => _quickBlocksKey = UniqueKey());
                    }
                  },
                  child: Row(
                    children: [
                      AnimatedRotation(
                        turns: quickBlocksExpanded ? 0 : -0.25,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary(context)),
                      ),
                      const SizedBox(width: 4),
                      Text('Quick Blocks', style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textSecondary(context))),
                    ],
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: quickBlocksExpanded
                      ? Column(
                    key: _quickBlocksKey,
                    children: [
                      const SizedBox(height: 12),
                      QuickBlockRow(reverseOnBuild: _quickBlocksCollapsing),
                    ],
                  )
                      : const SizedBox(width: double.infinity),
                ),
              ],
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
    setState(() => _isBreakRelatedSheetOpen = true); // 👈 new
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
    ).then((_) => setState(() => _isBreakRelatedSheetOpen = false)); // 👈 new
  }


  void _onGiveUp() {
    showDialog(
      context: context,
      builder: (ctx) => GiveUpDialog(
        onConfirm: () {
          Navigator.pop(ctx);
          ref.read(homeViewModelProvider.notifier).giveUp();
        },
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
    setState(() => _isBreakRelatedSheetOpen = true); // 👈 new
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
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppColors.border(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('☕️', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 12),
            Text(
              'Blocking Paused',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textPrimary(context),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your break is ongoing.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary(context),
                fontWeight: FontWeight.w600,
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
                  backgroundColor: const Color(0xFFFFE4A3),
                  foregroundColor: const Color(0xFF6B5417),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: const StadiumBorder(),
                  elevation: 0,
                  textStyle: AppTextStyles.labelLarge.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: const Text('End Break'),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ).then((_) => setState(() => _isBreakRelatedSheetOpen = false)); // 👈 new
  }
}