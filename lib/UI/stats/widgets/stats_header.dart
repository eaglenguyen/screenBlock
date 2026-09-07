import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'goal_settings_sheet.dart';

class StatsHeader extends ConsumerWidget {
  const StatsHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme
                .of(context)
                .brightness == Brightness.dark
                ? const Color(0xFF252015)
                : AppColors.backgroundCard(context),
            AppColors.background(context),
          ],
        ),
      ),
      child: Row(
        children: [
          Text(
            "Today's Stats",
            style: AppTextStyles.headlineSmall.copyWith(fontSize: 18),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => GoalSettingsSheet.show(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard(context),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                    color: AppColors.border(context), width: 0.5),
              ),
              child: Text(
                'Goals',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}