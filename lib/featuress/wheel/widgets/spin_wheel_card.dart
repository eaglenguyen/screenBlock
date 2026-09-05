// lib/featuress/wheel/widgets/spin_wheel_card.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'spin_wheel_sheet.dart';

class SpinWheelCard extends StatelessWidget {
  const SpinWheelCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => SpinWheelSheet.show(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(context), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.gold(context).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('🎡', style: TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Spin the Wheel', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary(context), fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Not sure what to do instead? Spin it.', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary(context))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary(context)),
          ],
        ),
      ),
    );
  }
}