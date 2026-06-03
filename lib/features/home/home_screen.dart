import 'package:flutter/material.dart';
import 'package:screenblock/features/home/timer/break_sheet.dart';
import 'package:screenblock/features/home/cards/countdown_card.dart';
import 'package:screenblock/features/home/cards/active_blocking_card.dart';
import 'package:screenblock/features/home/widgets/app_list_sheet.dart';
import 'package:screenblock/features/home/widgets/block_mode_sheet.dart';
import 'package:screenblock/features/home/widgets/focus_stats.dart';
import 'package:screenblock/features/home/widgets/home_header.dart';
import 'package:screenblock/features/home/cards/timer_card.dart';
import 'package:screenblock/features/home/timer/timer_picker_sheet.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/blocking_service_provider.dart';
import '../../services/xp_animation.dart';
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

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  bool _hasShownXpAnimation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // trigger load after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeViewModelProvider.notifier).init();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 👈 add
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // app came back to foreground — sync timer
      ref.read(homeViewModelProvider.notifier).onAppResumed();
      // 👇 reset overlay state on every resume
      ref.read(blockingServiceProvider).resetOverlayState();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeViewModelProvider);

    ref.listen(homeViewModelProvider, (previous, next) {
      debugPrint('🟡 phase change: ${previous?.phase} → ${next.phase}');
      if (previous?.phase == BlockingPhase.claimXp &&
          next.phase == BlockingPhase.idle &&
          !_hasShownXpAnimation) {
        debugPrint('✅ XP animation should trigger');
        debugPrint('✅ xpEarned: ${previous?.xpEarned}');
        _hasShownXpAnimation = true;
        // 👇 capture overlay before async gap
        final overlay = Overlay.of(context);
        // small delay to let home screen render first
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            debugPrint('✅ calling showXpGain');
            XpAnimation.instance.showXpGain(
              overlay:overlay,
              xpBadgeKey: _xpBadgeKey,
              xpAmount: previous?.xpEarned ?? 0,
            );
            // reset flag after animation
            Future.delayed(const Duration(milliseconds: 1000), () {
              _hasShownXpAnimation = false;
            });
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [

          HomeHeader(
              state: state,
              xpBadgeKey: _xpBadgeKey,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                14, 10, 14, 100,
              ),
              child: Column(
                children: [
                  // swap card based on phases
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
                      onAnimationStarted: () => ref
                          .read(homeViewModelProvider.notifier)
                          .resetAnimateBlockedTime(),
                    ),
                    BlockingPhase.countdown => CountdownCard(
                      count: state.remainingSeconds,
                      onCancel: _onCancelCountdown,
                    ),
                    BlockingPhase.active || BlockingPhase.onBreak =>
                        ActiveBlockingCard(
                          state: state,
                          onTakeBreak: _onTakeBreak,
                          onGiveUp: _onGiveUp,
                          onEndBreak: () => ref
                              .read(homeViewModelProvider.notifier)
                              .endBreak(),
                          onBlockListTapped: _onBlockListTapped,
                        ),
                    BlockingPhase.completed => SessionCompletedCard(
                      selectedMinutes: state.selectedMinutes,
                      xpEarned: state.xpEarned,
                      onFinish: () => ref
                          .read(homeViewModelProvider.notifier)
                          .finishAndUnblock(),
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
                  },
                  const SizedBox(height: 12),
                  if (state.phase == BlockingPhase.idle ||
                      state.phase == BlockingPhase.countdown)
                    FocusStatsCard(state: state),
                ],
              ),
            ),
          ),
        ],
      ),
    );

  }

  // Empty Callbacks
  void _onBlockNowTapped() {
    final state = ref.read(homeViewModelProvider);
    final notifier = ref.read(homeViewModelProvider.notifier);

    if (state.phase == BlockingPhase.idle) {
      // validate apps selected
      final hasApps = state.blockingType ==
          AppConstants.blockingTypeSpecificApps
          ? state.blockedApps.isNotEmpty
          : state.allowedApps.isNotEmpty;

      if (!hasApps) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.backgroundCard,
            content: Text(
              state.blockingType ==
                  AppConstants.blockingTypeSpecificApps
                  ? 'Add apps to block first'
                  : 'Add apps to allow first',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }
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
        selectedMinutes: ref
            .read(homeViewModelProvider)
            .selectedMinutes,
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
          ref
              .read(homeViewModelProvider.notifier)
              .startBreak(minutes);
        },
      ),
    );
  }

  void _onGiveUp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Give up?',
          style: AppTextStyles.headlineSmall,
          textAlign: TextAlign.center,
        ),
        content: Text(
          'This will stop your focus session.',
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
                ref
                    .read(homeViewModelProvider.notifier)
                    .giveUp();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),
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
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                shape: const StadiumBorder(),
                side: const BorderSide(
                  color: AppColors.border,
                ),
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
        initialApps: isAllApps
            ? state.allowedApps
            : state.blockedApps,
        onSave: (apps) {
          final notifier =
          ref.read(homeViewModelProvider.notifier);
          if (isAllApps) {
            notifier.setAllowedApps(apps);
          } else {
            notifier.setBlockedApps(apps);
          }
        },
      ),
    );
  }
}

