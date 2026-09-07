import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/schedule.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/lipped_card.dart';
import 'app_icon_stack.dart';
import 'hold_to_confirm.dart';

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
    this.isHardModeLocked = false
  });

  final Schedule schedule;
  final VoidCallback? onTap;
  final VoidCallback onToggle;
  final VoidCallback onPause;
  final bool isCurrentlyActive; // 👈 true when THIS schedule is blocking right now
  final bool isPaused; // 👈 true when paused
  final int pauseRemainingSeconds;
  final bool isHardModeLocked;

  String _formatRemaining(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0) {
      return '${m}m ${s.toString().padLeft(2, '0')}s';
    }
    return '${s}s';
  }

  List<String> get _relevantApps => schedule.blockingType == AppConstants.blockingTypeSpecificApps
      ? schedule.blockedApps
      : schedule.allowedApps;


  void _showGiveUpConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'You sure you want to unblock?',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textPrimary(context),
          ),
          textAlign: TextAlign.center,
        ),
        content: Text.rich(
          TextSpan(
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary(context),
            ),
            children: [
              const TextSpan(text: 'Think twice before unblocking, do something more '),
              TextSpan(
                text: 'productive',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.w800),
              ),
              const TextSpan(text: ' or try pausing instead! '),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox( // 👈 new — explicit finite width wrapper
            width: MediaQuery.of(context).size.width * 0.7,
            child: HoldToConfirmButton(
              onConfirmed: () {
                Navigator.pop(ctx);
                onToggle();
              },
              color: AppColors.error(context),
              fillColor: Color.lerp(AppColors.error(context), Colors.black, 0.3)!,
              textColor: Colors.white,
              label: 'Hold to Give Up',
              holdingLabel: 'Keep holding...',
              doneLabel: 'Giving up',
              holdDuration: const Duration(seconds: 7),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity, // 👈 this one is fine — plain OutlinedButton, not HoldToConfirmButton
            child: OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary(context),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const StadiumBorder(),
                side: BorderSide(color: AppColors.border(context)),
              ),
              child: const Text('No, continue blocking'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LippedCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque, // 👈 new
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isCurrentlyActive
                          ? AppColors.accent(context)
                          : schedule.isActive
                          ? AppColors.accent(context).withValues(alpha: 0.4)
                          : AppColors.textSecondary(context),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  AppIconStack(
                    packageNames: _relevantApps,
                    iosStorageKey: 'schedule_${schedule.id}_${schedule.blockingType}',
                    refreshToken: schedule.updatedAt.millisecondsSinceEpoch,
                    size: 40,
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
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textPrimary(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (schedule.isActive) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isCurrentlyActive
                                      ? isPaused
                                      ? Colors.orange.withValues(alpha: 0.15)
                                      : AppColors.accent(context).withValues(alpha: 0.15)
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
                                        : AppColors.accent(context)
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
                  Opacity(
                    opacity: isHardModeLocked ? 0.35 : 1.0,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque, // 👈 new
                      onTap: isHardModeLocked
                          ? null
                          : () {
                        if (schedule.isActive && isCurrentlyActive) {
                          _showGiveUpConfirmation(context);
                        } else {
                          onToggle();
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44,
                          height: 24,
                          decoration: BoxDecoration(
                            color: schedule.isActive
                                ? AppColors.accent(context)
                                : AppColors.backgroundSubtle(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border(context), width: 0.5),
                          ),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 200),
                            alignment: schedule.isActive ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: AppColors.textPrimary(context),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isCurrentlyActive)
            Opacity(
              opacity: isHardModeLocked ? 0.35 : 1.0,
              child: GestureDetector(
                onTap: isHardModeLocked ? null : onPause,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: isPaused
                        ? Colors.orange.withValues(alpha: 0.1)
                        : AppColors.backgroundSubtle(context),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                            color: isPaused ? Colors.orange : AppColors.textSecondary(context),
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isPaused ? 'Pause Time Remaining...' : 'Pause blocking',
                            style: TextStyle(
                              color: isPaused ? Colors.orange : AppColors.textSecondary(context),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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
            ),
        ],
      ),
    );
  }
}