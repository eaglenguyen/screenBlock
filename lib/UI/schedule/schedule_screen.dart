import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pausenow/UI/schedule/schedule_viewmodel.dart';
import 'package:pausenow/UI/schedule/widgets/pause_sheet.dart';
import 'package:pausenow/UI/schedule/widgets/session_bottom_sheet.dart';
import 'package:pausenow/UI/schedule/widgets/session_card.dart';
import 'package:pausenow/UI/schedule/widgets/session_mode_picker_sheet.dart';
import 'package:pausenow/core/theme/lipped_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/schedule.dart';
import '../../../paywall/feature_paywall_screen.dart';
import '../../../providers/premium_provider.dart';
import '../../../services/schedule_checker.dart';
import '../../core/utils/permission_dialogs.dart';
import '../../data/models/time_limit_config.dart';
import '../../featuress/quickblock/widgets/quick_block_row.dart';
import '../../featuress/timelimit/time_limit_viewmodel.dart';
import '../../featuress/timelimit/widget/time_limit_bottom_sheet.dart';
import '../../featuress/timelimit/widget/time_limit_card.dart';
import '../../featuress/timelimit/widget/time_limit_option_sheet.dart';
import '../home/home_state.dart';
import '../home/home_viewmodel.dart';
import '../settings/settings_viewmodel.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scheduleViewModelProvider);
    final timeLimitState = ref.watch(timeLimitViewModelProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final isManualBlocking = ref.watch(homeViewModelProvider).phase == BlockingPhase.active;
    final isPaused = ref.watch(homeViewModelProvider).phase == BlockingPhase.onBreak;
    final hardModeEnabled = ref.watch(settingsViewModelProvider).hardModeEnabled; // 👈 new



    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Column(
        children: [
          _buildHeader(context, ref),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                14, 8, 14, 100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isManualBlocking || isPaused)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.error(context).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.error(context).withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.block_rounded,
                              color: AppColors.error(context), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'End your manual session to manage schedules',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.error(context),
                                fontSize: 12
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Replace the schedules map section in build():
                  if (state.schedules.isNotEmpty) ...[
                    ReorderableListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      onReorder: (oldIndex, newIndex) {
                        ref.read(scheduleViewModelProvider.notifier)
                            .reorderSchedules(oldIndex, newIndex);
                      },
                      // 👇 long press anywhere to drag
                      buildDefaultDragHandles: true,
                      children: state.schedules.asMap().entries.map((entry) {
                        final i = entry.key;
                        final s = entry.value;
                        final isLocked = !isPremium && i >= 1;

                        // 👇 new — pulled out so it can be reused below
                        final isThisScheduleCurrentlyActive =
                            ref.watch(homeViewModelProvider).isScheduleActive &&
                                ScheduleChecker.instance.activeScheduleId == s.id;

                        final isHardModeLocked = hardModeEnabled && isThisScheduleCurrentlyActive; // 👈 new

                        return Padding(
                          key: ValueKey(s.id),
                          padding: const EdgeInsets.only(bottom: 10),
                          child: isLocked
                              ? _LockedScheduleCard(schedule: s)
                              : Opacity(
                            opacity: (isManualBlocking || isPaused || isHardModeLocked) ? 0.4 : 1.0, // 👈 added isHardModeLocked
                            child: IgnorePointer(
                              ignoring: isManualBlocking || isPaused || isHardModeLocked, // 👈 added isHardModeLocked — blocks the whole card, including onTap
                              child: SessionCard(
                                schedule: s,
                                onTap: isManualBlocking || isPaused
                                    ? null
                                    : () => _openEditSession(context, ref, s),
                                onToggle: isManualBlocking || isPaused
                                    ? () {}
                                    : () => checkAccessibilityAndProceed(
                                  context,
                                  ref,
                                      () => ref
                                      .read(scheduleViewModelProvider.notifier)
                                      .toggleSchedule(s.id),
                                ),
                                isCurrentlyActive: isThisScheduleCurrentlyActive,
                                isPaused: ref.watch(homeViewModelProvider).isSchedulePaused,
                                pauseRemainingSeconds: ref
                                    .watch(homeViewModelProvider)
                                    .schedulePauseRemainingSeconds,
                                isHardModeLocked: isHardModeLocked,
                                onPause: () {
                                  final homeState = ref.read(homeViewModelProvider);
                                  PauseScheduleSheet.show(
                                    context,
                                    isPaused: homeState.isSchedulePaused,
                                    onResume: () => ref
                                        .read(homeViewModelProvider.notifier)
                                        .resumeSchedule(),
                                    onPause: (mins) => ref
                                        .read(homeViewModelProvider.notifier)
                                        .pauseSchedule(mins),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 4),

                  ] else ...[
                    _buildEmptyState(context),
                  ],


                  // 👇 NEW — time-limit section
                  if (timeLimitState.configs.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Time Limits',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...timeLimitState.configs.asMap().entries.map((entry) {
                      final i = entry.key;
                      final config = entry.value;
                      final isLocked = !isPremium && i >= 1; // 👈 same pattern as schedules

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: isLocked
                            ? _LockedTimeLimitCard(config: config)
                            : Opacity(
                          opacity: isManualBlocking || isPaused ? 0.4 : 1.0,
                          child: IgnorePointer(
                            ignoring: isManualBlocking || isPaused,
                            child: TimeLimitCard(
                              config: config,
                              onTap: () => TimeLimitOptionsSheet.show(
                                context,
                                config: config,
                                isLimitReached: false,
                                onEdit: () => showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  useRootNavigator: true,
                                  builder: (_) => TimeLimitBottomSheet(existingConfig: config),
                                ),
                                onDelete: () => ref.read(timeLimitViewModelProvider.notifier).deleteConfig(config.id),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 16),
                  const QuickBlockRow()

                  // Removed
                  // const BlockedAppsCard(), and preset()

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildEmptyState(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Transform.rotate(
              angle: -0.6,
              child: Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.accent(context),
                size: 48,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create a Custom Schedule',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final isManualBlocking = ref.watch(homeViewModelProvider).phase == BlockingPhase.active;
    final isPaused = ref.watch(homeViewModelProvider).phase == BlockingPhase.onBreak;
    final isLocked = isManualBlocking || isPaused;


    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
      decoration:  BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF252015)
                : AppColors.backgroundCard(context),
            AppColors.background(context),          ],
        ),
      ),
      child: Row(
        children: [
          Text('Schedules', style: AppTextStyles.headlineMedium),
          const Spacer(),
          GestureDetector(
            onTap: isLocked ? null : () => _openCreateSession(context, ref), // 👈
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isLocked
                    ? AppColors.backgroundSubtle(context) // 👈 grayed out
                    : AppColors.accent(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                color: isLocked
                    ? AppColors.textSecondary(context) // 👈 muted icon
                    : AppColors.accentText(context),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openCreateSession(BuildContext context, WidgetRef ref) {
    checkAccessibilityAndProceed(context, ref, () {
      SessionModePickerSheet.show(
        context,
        onScheduleTap: () {
          final isPremium = ref.read(isPremiumProvider);
          final scheduleCount = ref.read(scheduleViewModelProvider).schedules.length;

          if (!isPremium && scheduleCount >= 1) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              useRootNavigator: true,
              builder: (_) => const FeaturePaywallScreen(source: 'multiple_schedules'),
            );
            return;
          }

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            useRootNavigator: true,
            builder: (_) => const SessionBottomSheet(),
          );
        },
        onTimeLimitTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            useRootNavigator: true,
            builder: (_) => const TimeLimitBottomSheet(),
          );
        },
      );
    });
  }

  void _openEditSession(
      BuildContext context,
      WidgetRef ref,
      Schedule schedule,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => SessionBottomSheet(
        existingSchedule: schedule,
      ),
    );
  }
}


// ── Locked schedule card widget ───────────────────────

class _LockedScheduleCard extends StatelessWidget {
  final Schedule schedule;

  const _LockedScheduleCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // dimmed card
        Opacity(
          opacity: 0.4,
          child: LippedCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary(context),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(schedule.name,
                          style: AppTextStyles.labelMedium),
                      const SizedBox(height: 3),
                      Text(
                        '${schedule.timeRange} · ${schedule.daysDisplay}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // lock overlay
        Positioned.fill(
          child: GestureDetector(
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              useRootNavigator: true,
              builder: (_) => const FeaturePaywallScreen(source: 'locked_schedule_card'),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_rounded,
                    color: AppColors.accent(context),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Upgrade to unlock',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.accent(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LockedTimeLimitCard extends StatelessWidget {
  final TimeLimitConfig config;

  const _LockedTimeLimitCard({required this.config});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(
          opacity: 0.4,
          child: LippedCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accent(context).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(child: Text('⏱️', style: TextStyle(fontSize: 18))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(config.name, style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textPrimary(context),
                        fontWeight: FontWeight.w700,
                      )),
                      const SizedBox(height: 4),
                      Text('${config.limitMinutes}m/day · ${config.packageNames.length} apps',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary(context))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: GestureDetector(
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              useRootNavigator: true,
              builder: (_) => const FeaturePaywallScreen(source: 'locked_time_limit_card'),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_rounded, color: AppColors.accent(context), size: 16),
                  const SizedBox(width: 8),
                  Text('Upgrade to unlock', style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.accent(context),
                    fontWeight: FontWeight.w700,
                  )),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}



//

