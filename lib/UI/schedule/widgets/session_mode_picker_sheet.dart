import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SessionModePickerSheet extends StatelessWidget {
  final VoidCallback onScheduleTap;
  final VoidCallback onTimeLimitTap;

  const SessionModePickerSheet({
    super.key,
    required this.onScheduleTap,
    required this.onTimeLimitTap,
  });

  static void show(
      BuildContext context, {
        required VoidCallback onScheduleTap,
        required VoidCallback onTimeLimitTap,
      }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => SessionModePickerSheet(
        onScheduleTap: onScheduleTap,
        onTimeLimitTap: onTimeLimitTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        left: 20,
        right: 20,
        top: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Create a Session',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Choose how you want to block apps',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _modeCard(
                  context,
                  emoji: '🧘',
                  title: 'Schedule',
                  subtitle: 'Specific days & times',
                  onTap: () {
                    Navigator.pop(context);
                    onScheduleTap();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _modeCard(
                  context,
                  emoji: '⏱️',
                  title: 'Time Limit',
                  subtitle: 'Daily usage cap',
                  onTap: () {
                    Navigator.pop(context);
                    onTimeLimitTap();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _modeCard(
                  context,
                  emoji: '🔢',
                  title: 'Open Limit',
                  subtitle: 'Coming soon',
                  onTap: null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeCard(
      BuildContext context, {
        required String emoji,
        required String title,
        required String subtitle,
        required VoidCallback? onTap,
      }) {
    final isDisabled = onTap == null;

    return Opacity(
      opacity: isDisabled ? 0.4 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.backgroundSubtle(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border(context), width: 0.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.gold(context).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary(context),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}