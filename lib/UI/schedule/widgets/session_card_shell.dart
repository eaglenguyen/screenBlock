
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';


class SessionCardShell extends StatelessWidget {
  final Widget icon;
  final String name;
  final int? streakCount;
  final VoidCallback onOptionsTap;
  final Widget bottomAction;
  final bool showBetaFlair; // 👈 new

  const SessionCardShell({
    super.key,
    required this.icon,
    required this.name,
    this.streakCount,
    required this.onOptionsTap,
    required this.bottomAction,
    this.showBetaFlair = false, // 👈 new
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOptionsTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border(context), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (showBetaFlair) // 👈 new — takes priority over streak badge in this corner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.4), width: 0.5),
                    ),
                    child: Text(
                      'BETA',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                        letterSpacing: 0.3,
                      ),
                    ),
                  )
                else if (streakCount != null && streakCount! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.5), width: 1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 11)),
                        const SizedBox(width: 3),
                        Text(
                          '$streakCount',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const SizedBox(width: 1),
                Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary(context)),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(width: 48, height: 48, child: icon),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_rounded, size: 14, color: AppColors.accent(context)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            bottomAction,
          ],
        ),
      ),
    );
  }
}