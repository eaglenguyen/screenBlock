import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/lipped_card.dart';

class BreakConfirmationCard extends StatelessWidget {
  final VoidCallback onYes;
  final VoidCallback onNo;

  const BreakConfirmationCard({
    super.key,
    required this.onYes,
    required this.onNo,
  });

  @override
  Widget build(BuildContext context) {
    return LippedCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🍅', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'Work session complete!',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textPrimary(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Ready to start your break?',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onNo,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary(context),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const StadiumBorder(),
                    side: BorderSide(color: AppColors.border(context)),
                  ),
                  child: const Text('No, stop'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onYes,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent(context),
                    foregroundColor: AppColors.accentText(context),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const StadiumBorder(),
                    textStyle: AppTextStyles.labelLarge,
                  ),
                  child: const Text('Yes, break'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}