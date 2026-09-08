import 'package:flutter/material.dart';
import '../../../UI/schedule/widgets/session_card_shell.dart';
import '../../../UI/schedule/widgets/app_icon_stack.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/lock_app_config.dart';

class LockAppCard extends StatelessWidget {
  final LockAppConfig config;
  final VoidCallback onOptionsTap;
  final VoidCallback onUnlockTap;

  const LockAppCard({
    super.key,
    required this.config,
    required this.onOptionsTap,
    required this.onUnlockTap,
  });

  @override
  Widget build(BuildContext context) {
    final isExhausted = config.isExhausted;
    return SessionCardShell(
      icon: AppIconStack(
        packageNames: [config.packageName],
        iosStorageKey: 'lockApp_${config.id}',
        refreshToken: config.updatedAt.millisecondsSinceEpoch,
        size: 48,
      ),
      name: config.appName,
      onOptionsTap: onOptionsTap,
      bottomAction: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: isExhausted ? null : onUnlockTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary(context),
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: const StadiumBorder(),
            side: BorderSide(color: AppColors.border(context)),
            disabledForegroundColor: AppColors.textSecondary(context).withValues(alpha: 0.5),
          ),
          child: Text(
            'Unlock (${config.unlocksUsedToday}/${config.maxUnlocks})',
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}