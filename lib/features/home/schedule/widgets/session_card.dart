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
    required this.onPause,
    this.isCurrentlyActive = false,
    this.isPaused = false,
  });

  final Schedule schedule;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onPause;
  final bool isCurrentlyActive; // 👈 true when THIS schedule is blocking right now
  final bool isPaused; // 👈 true when paused

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Main card ──────────────────────────────
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isCurrentlyActive ? 0 : 16),
                bottomRight: Radius.circular(isCurrentlyActive ? 0 : 16),
              ),
              border: Border.all(
                color: isCurrentlyActive
                    ? AppColors.gold.withValues(alpha: 0.4)
                    : schedule.isActive
                    ? AppColors.gold.withValues(alpha: 0.2)
                    : AppColors.border,
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                // active indicator dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isCurrentlyActive
                        ? AppColors.gold
                        : schedule.isActive
                        ? AppColors.gold.withValues(alpha: 0.4)
                        : AppColors.textSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            schedule.name,
                            style: AppTextStyles.labelMedium,
                          ),
                          if (isCurrentlyActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isPaused
                                    ? Colors.orange.withValues(alpha: 0.15)
                                    : AppColors.gold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isPaused ? 'Paused' : 'Active',
                                style: TextStyle(
                                  color: isPaused
                                      ? Colors.orange
                                      : AppColors.gold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${schedule.timeRange} · ${schedule.daysDisplay}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                // toggle
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
        ),

        // ── Pause button — only shown when active ──
        if (isCurrentlyActive)
          GestureDetector(
            onTap: onPause,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isPaused
                    ? Colors.orange.withValues(alpha: 0.1)
                    : AppColors.backgroundSubtle,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                  left: BorderSide(
                    color: isPaused
                        ? Colors.orange.withValues(alpha: 0.4)
                        : AppColors.border,
                    width: 0.5,
                  ),
                  right: BorderSide(
                    color: isPaused
                        ? Colors.orange.withValues(alpha: 0.4)
                        : AppColors.border,
                    width: 0.5,
                  ),
                  bottom: BorderSide(
                    color: isPaused
                        ? Colors.orange.withValues(alpha: 0.4)
                        : AppColors.border,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPaused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    color: isPaused
                        ? Colors.orange
                        : AppColors.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isPaused ? 'Resume blocking' : 'Pause blocking',
                    style: TextStyle(
                      color: isPaused
                          ? Colors.orange
                          : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}