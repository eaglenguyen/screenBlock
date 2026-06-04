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
            "Today's Screen Time",
            style: AppTextStyles.headlineSmall.copyWith(fontSize: 18),
          ),
          const Spacer(),
          if (Platform.isIOS) ...[
            _iconButton(
              icon: Icons.access_time_rounded,
              onTap: () async {
                await const MethodChannel(
                  'com.eagle.screenblock/ios_blocking',
                ).invokeMethod('openScreenTime');
              },
            ),
            const SizedBox(width: 8),
          ],
          _iconButton(
            icon: Icons.refresh_rounded,
            onTap: () => ref
                .read(statsViewModelProvider.notifier)
                .loadStats(),
          ),
          const SizedBox(width: 8),
          _iconButton(
            icon: Icons.punch_clock,
            onTap: () => GoalSettingsSheet.show(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 16),
      ),
    );
  }
}