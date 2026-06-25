import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pausenow/features/home/schedule/widgets/session_bottom_sheet.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../providers/premium_provider.dart';
import '../../../paywall/feature_paywall_screen.dart';
import '../../home_state.dart';
import '../../home_viewmodel.dart';
import '../schedule_viewmodel.dart';
import 'schedule_presets.dart';


class PresetsSection extends ConsumerWidget {
  const PresetsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 0, 12),
          child: Text(
            'Schedules',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textPrimary(context),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundCard(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border(context), width: 0.5),
          ),
          child: Column(
            children: List.generate(schedulePresets.length, (i) {
              final preset = schedulePresets[i];
              final isLast = i == schedulePresets.length - 1;
              return Column(
                children: [
                  _PresetRow(preset: preset, ref: ref,),
                  if (!isLast)
                    Divider(
                      height: 0.5,
                      thickness: 0.5,
                      color: AppColors.border(context),
                      indent: 16,
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _PresetRow extends StatelessWidget {
  final SchedulePreset preset;
  final WidgetRef ref;
  const _PresetRow({required this.preset, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isManualBlocking = ref.watch(homeViewModelProvider).phase == BlockingPhase.active;
    final isPaused = ref.watch(homeViewModelProvider).phase == BlockingPhase.onBreak;
    final isLocked = isManualBlocking || isPaused;

    return InkWell(
      onTap: isLocked ? null : () { // 👈 disable when manual blocking
        final isPremium = ref.read(isPremiumProvider);
        final scheduleCount = ref.read(scheduleViewModelProvider).schedules.length;

        if (!isPremium && scheduleCount >= 1) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            useRootNavigator: true,
            builder: (_) => const FeaturePaywallScreen(),
          );
          return;
        }

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          useRootNavigator: true,
          builder: (_) => SessionBottomSheet(preset: preset),
        );
      },

        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: isLocked  ? 0.4 : 1.0, // 👈 dim when disabled
          child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // emoji circle
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: preset.accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(preset.emoji, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            // name + time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.name,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textPrimary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${_fmt(preset.startTime)} - ${_fmt(preset.endTime)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // + button
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: preset.accentColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
        ),
    );
  }

  String _fmt(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : hour > 12 ? hour - 12 : hour;
    return '$displayHour:${parts[1]} $period';
  }
}