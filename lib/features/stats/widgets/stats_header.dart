import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../stats_viewmodel.dart';
import 'goal_settings_sheet.dart';

class StatsHeader extends ConsumerWidget {
  const StatsHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          Text(
            "Today's Stats",
            style: AppTextStyles.headlineSmall.copyWith(fontSize: 18),
          ),
          const Spacer(),
          if (Platform.isIOS) ...[
            _iconButton(
              icon: Icons.access_time_rounded,
              onTap: () async {
                await const MethodChannel(
                  'com.eagle.pausenow/ios_blocking',
                ).invokeMethod('openScreenTime');
              },
                context: context

            ),
            const SizedBox(width: 8),
          ],
          _iconButton(
            icon: Icons.timelapse,
            onTap: () => GoalSettingsSheet.show(context, ref),
              context: context
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required VoidCallback onTap,
    required BuildContext context
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.backgroundCard(context),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border(context), width: 0.5),
        ),
        child: Icon(icon, color: AppColors.textSecondary(context), size: 16),
      ),
    );
  }
}