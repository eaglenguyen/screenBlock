import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
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
    return SizedBox( // 👈 new — forces LippedCard to actually span full width
      width: double.infinity,
      child: LippedCard(
        padding: const EdgeInsets.symmetric(
          vertical: 44,
          horizontal: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // 👈 new — keeps children from shrinking to their own content width
          children: [
            Text(
              'Blocking apps in',
              textAlign: TextAlign.center, // 👈 new — since the column now stretches, center the text explicitly
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
                textAlign: TextAlign.center, // 👈 new
                style: TextStyle(
                  fontSize: 110,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary(context),
                  height: 1,
                ),
              ),
            ),
            const SizedBox(height: 36),
            GestureDetector(
              onTap: onCancel,
              child: Center( // 👈 new — since the column now stretches, center this button explicitly
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSubtle(context),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: AppColors.border(context), width: 0.5),
                  ),
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