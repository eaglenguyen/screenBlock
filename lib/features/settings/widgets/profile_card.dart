import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SettingsProfileCard extends StatelessWidget {
  const SettingsProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Device',
                style: AppTextStyles.labelMedium.copyWith(
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Local account · No sign in required',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        color: AppColors.gold,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          'U',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.goldText,
            fontSize: 22,
          ),
        ),
      ),
    );
  }
}