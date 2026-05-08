import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/schedule.dart';

class SessionCard extends StatelessWidget {
  const SessionCard({
    super.key,
    required this.schedule,
    required this.onTap,
    required this.onToggle,
  });

  final Schedule schedule;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: schedule.isActive
                ? AppColors.gold.withOpacity(0.4)
                : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // active indicator
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: schedule.isActive
                    ? AppColors.gold
                    : AppColors.textSecondary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.name,
                    style: AppTextStyles.labelMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${schedule.timeRange} · ${schedule.daysDisplay}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            // toggle switch
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  color: schedule.isActive
                      ? AppColors.gold
                      : AppColors.backgroundSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.border,
                    width: 0.5,
                  ),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: schedule.isActive
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: AppColors.textPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}