import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/lipped_button.dart';
import '../../../core/theme/lipped_card.dart';

class CountdownCard extends StatelessWidget {
  const CountdownCard({
    super.key,
    required this.count,
    required this.onCancel,
  });

  final int count;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: LippedCard(
        padding: const EdgeInsets.symmetric(
          vertical: 44,
          horizontal: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Blocking apps in',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: Text(
                '$count',
                key: ValueKey(count),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 110,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary(context),
                  height: 1,
                ),
              ),
            ),
            const SizedBox(height: 36),
            Center( // 👈 kept — LippedButton is width: double.infinity internally, so still need to constrain it
              child: SizedBox(
                width: 160, // 👈 new — gives the pill a fixed, non-full-width size, matching its original compact look
                child: LippedButton( // 👈 was GestureDetector/Container
                  onTap: onCancel,
                  color: AppColors.backgroundSubtle(context),
                  lipColor: AppColors.border(context),
                  height: 46,
                  borderRadius: BorderRadius.circular(50),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary(context),
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Cancel',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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