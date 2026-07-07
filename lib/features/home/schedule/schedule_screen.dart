import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pausenow/features/home/schedule/schedule_viewmodel.dart';
import 'package:pausenow/features/home/schedule/widgets/pause_sheet.dart';
import 'package:pausenow/features/home/schedule/widgets/presets_section.dart';
import 'package:pausenow/features/home/schedule/widgets/session_bottom_sheet.dart';
import 'package:pausenow/features/home/schedule/widgets/session_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/schedule.dart';
import '../../../paywall/feature_paywall_screen.dart';
import '../../../providers/blocking_service_provider.dart';
import '../../../providers/premium_provider.dart';
import '../../../services/schedule_checker.dart';
import '../home_state.dart';
import '../home_viewmodel.dart';


class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scheduleViewModelProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final isManualBlocking = ref.watch(homeViewModelProvider).phase == BlockingPhase.active;
    final isPaused = ref.watch(homeViewModelProvider).phase == BlockingPhase.onBreak;



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
                        return Padding(
                          key: ValueKey(s.id),
                          padding: const EdgeInsets.only(bottom: 10),
                            child: isLocked
                                ? _LockedScheduleCard(schedule: s)
                                : Opacity(
                              opacity: isManualBlocking || isPaused ? 0.4 : 1.0, // 👈 gray out when locked
                              child: IgnorePointer(
                                ignoring: isManualBlocking || isPaused, // 👈 block all taps
                                child: SessionCard(
                                  schedule: s,
                                  onTap: isManualBlocking || isPaused
                                      ? null
                                      : () => _openEditSession(context, ref, s),
                                  onToggle: isManualBlocking || isPaused
                                      ? () {}
                                      : () => _checkAccessibilityAndProceed(
                                    context,
                                    ref,
                                        () => ref
                                        .read(scheduleViewModelProvider.notifier)
                                        .toggleSchedule(s.id),
                                  ),
                                  isCurrentlyActive:
                                  ref.watch(homeViewModelProvider).isScheduleActive &&
                                      ScheduleChecker.instance.activeScheduleId == s.id,
                                  isPaused: ref.watch(homeViewModelProvider).isSchedulePaused,
                                  pauseRemainingSeconds: ref
                                      .watch(homeViewModelProvider)
                                      .schedulePauseRemainingSeconds,
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

                  const SizedBox(height: 16),
                  const PresetsSection(), // 👈 add this

                  // Removed
                  // const BlockedAppsCard(),

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
                color: AppColors.gold(context),
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
          Text('Scheduled Sessions', style: AppTextStyles.headlineMedium),
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
                    : AppColors.gold(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                color: isLocked
                    ? AppColors.textSecondary(context) // 👈 muted icon
                    : AppColors.goldText(context),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openCreateSession(BuildContext context, WidgetRef ref) {
    _checkAccessibilityAndProceed(context, ref, () {
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
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.border(context),
                width: 0.5,
              ),
            ),
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
                    color: AppColors.gold(context),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Upgrade to unlock',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.gold(context),
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

Future<void> _checkAccessibilityAndProceed(
    BuildContext context,
    WidgetRef ref,
    VoidCallback onGranted,
    ) async {
  if (!Platform.isAndroid) {
    onGranted();
    return;
  }

  final service = ref.read(blockingServiceProvider);
  final hasAccessibility = await service.hasAccessibilityPermission();

  if (!context.mounted) return;

  if (hasAccessibility) {
    onGranted();
    return;
  }

  // 👇 show dialog before going to settings
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.backgroundCard(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.gold(context).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.accessibility_new_rounded,
              color: AppColors.gold(context),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Accessibility Required',
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Accessibility permission needed to block apps. Tap below to enable it in Settings.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await service.requestAccessibilityPermission();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold(context),
              foregroundColor: AppColors.goldText(context),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              'Open Settings',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Not Now',
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
//

