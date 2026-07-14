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
    this.pauseRemainingSeconds = 0,

  });

  final Schedule schedule;
  final VoidCallback? onTap;
  final VoidCallback onToggle;
  final VoidCallback onPause;
  final bool isCurrentlyActive; // 👈 true when THIS schedule is blocking right now
  final bool isPaused; // 👈 true when paused
  final int pauseRemainingSeconds;

  String _formatRemaining(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0) {
      return '${m}m ${s.toString().padLeft(2, '0')}s';
    }
    return '${s}s';
  }


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
              color: AppColors.backgroundCard(context),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isCurrentlyActive ? 0 : 16),
                bottomRight: Radius.circular(isCurrentlyActive ? 0 : 16),
              ),
              border: Border.all(
                color: isCurrentlyActive
                    ? AppColors.gold(context).withValues(alpha: 0.4)
                    : schedule.isActive
                    ? AppColors.gold(context).withValues(alpha: 0.2)
                    : AppColors.border(context),
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
                        ? AppColors.gold(context)
                        : schedule.isActive
                        ? AppColors.gold(context).withValues(alpha: 0.4)
                        : AppColors.textSecondary(context),
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
                          if (schedule.isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isCurrentlyActive
                                    ? isPaused
                                    ? Colors.orange.withValues(alpha: 0.15)
                                    : AppColors.gold(context).withValues(alpha: 0.15)
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isCurrentlyActive
                                    ? isPaused
                                    ? 'Paused'
                                    : 'Active'
                                    : 'Inactive',
                                style: TextStyle(
                                  color: isCurrentlyActive
                                      ? isPaused
                                      ? Colors.orange
                                      : AppColors.gold(context)
                                      : Colors.white.withValues(alpha: 0.3),
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
                          ? AppColors.gold(context)
                          : AppColors.backgroundSubtle(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.border(context),
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
                        decoration:  BoxDecoration(
                          color: AppColors.textPrimary(context),
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
              padding: const EdgeInsets.symmetric(vertical: 18), // 👈 bigger from 12
              decoration: BoxDecoration(
                color: isPaused
                    ? Colors.orange.withValues(alpha: 0.1)
                    : AppColors.backgroundSubtle(context),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                  left: BorderSide(
                    color: isPaused
                        ? Colors.orange.withValues(alpha: 0.4)
                        : AppColors.border(context),
                    width: 0.5,
                  ),
                  right: BorderSide(
                    color: isPaused
                        ? Colors.orange.withValues(alpha: 0.4)
                        : AppColors.border(context),
                    width: 0.5,
                  ),
                  bottom: BorderSide(
                    color: isPaused
                        ? Colors.orange.withValues(alpha: 0.4)
                        : AppColors.border(context),
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isPaused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        color: isPaused
                            ? Colors.orange
                            : AppColors.textSecondary(context),
                        size: 20, // 👈 bigger from 16
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isPaused ? 'Pause Time Remaining...' : 'Pause blocking',
                        style: TextStyle(
                          color: isPaused
                              ? Colors.orange
                              : AppColors.textSecondary(context),
                          fontSize: 15, // 👈 bigger from 13
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  // 👇 countdown when paused
                  if (isPaused && pauseRemainingSeconds > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      _formatRemaining(pauseRemainingSeconds),
                      style: TextStyle(
                        color: Colors.orange.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}