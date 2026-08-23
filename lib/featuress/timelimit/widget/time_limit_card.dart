import 'package:flutter/material.dart';
import '../../../UI/schedule/widgets/app_icon_stack.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/time_limit_config.dart';

class TimeLimitCard extends StatelessWidget {
  final TimeLimitConfig config;
  final VoidCallback? onTap;

  const TimeLimitCard({
    super.key,
    required this.config,
    required this.onTap,
  });

  String get _daysLabel {
    final days = config.days;
    if (days.length == 7) return 'Every day';
    if (days.length == 5 && !days.contains(5) && !days.contains(6)) return 'Weekdays';
    if (days.length == 2 && days.contains(5) && days.contains(6)) return 'Weekends';
    return 'Custom';
  }

  String get _limitLabel {
    final m = config.limitMinutes;
    if (m < 60) return '${m}m';
    final h = m ~/ 60;
    final rem = m % 60;
    return rem == 0 ? '${h}h' : '${h}h ${rem}m';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(context), width: 0.5),
        ),
        child: Row(
          children: [
            AppIconStack(
              packageNames: config.packageNames, // used on Android
              iosStorageKey: 'timeLimitApps_${config.id}', // used on iOS
              refreshToken: config.updatedAt.millisecondsSinceEpoch, // 👈 simplest option — changes whenever the app list itself changes
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.name,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textPrimary(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$_limitLabel/day · ${config.packageNames.length} apps · $_daysLabel',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}