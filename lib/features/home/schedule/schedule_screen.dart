import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenblock/features/home/schedule/schedule_viewmodel.dart';
import 'package:screenblock/features/home/schedule/widgets/blocked_apps_card.dart';
import 'package:screenblock/features/home/schedule/widgets/session_bottom_sheet.dart';
import 'package:screenblock/features/home/schedule/widgets/session_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/schedule.dart';


class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scheduleViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                14, 8, 14, 100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // session cards
                  if (state.schedules.isNotEmpty) ...[
                    ...state.schedules.map(
                          (s) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: 10,
                        ),
                        child: SessionCard(
                          schedule: s,
                          onTap: () => _openEditSession(
                            context, ref, s,
                          ),
                          onToggle: () => ref
                              .read(scheduleViewModelProvider
                              .notifier)
                              .toggleSchedule(s.id),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],

                  // blocked apps card
                  const BlockedAppsCard(),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1e1e40), AppColors.background],
        ),
      ),
      child: Row(
        children: [
          Text(
            'Scheduled Sessions',
            style: AppTextStyles.headlineMedium,
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _openCreateSession(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: AppColors.goldText,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openCreateSession(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SessionBottomSheet(),
    );
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
      builder: (_) => SessionBottomSheet(
        existingSchedule: schedule,
      ),
    );
  }
}
//