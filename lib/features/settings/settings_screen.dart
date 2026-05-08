import 'package:flutter/material.dart';
import 'package:screenblock/features/settings/settings_viewmodel.dart';
import 'package:screenblock/features/settings/widgets/profile_card.dart';
import 'package:screenblock/features/settings/widgets/settings_section.dart';
import '../../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_text_styles.dart';


class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsViewModelProvider);
    final notifier = ref.read(settingsViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                14, 12, 14, 100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // profile
                  const SettingsProfileCard(),
                  const SizedBox(height: 12),


                  // support
                  SettingsSection(
                    label: 'Support',
                    rows: [
                      SettingsRow(
                        icon: Icons.help_outline_rounded,
                        iconColor: const Color(0xFF4A9EFF),
                        iconBgColor: const Color(0xFF1e2d4a),
                        label: 'Get Help',
                        onTap: () {},
                      ),
                      SettingsRow(
                        icon: Icons.chat_bubble_outline_rounded,
                        iconColor: const Color(0xFF4A9EFF),
                        iconBgColor: const Color(0xFF1e2d4a),
                        label: 'Give Feedback',
                        onTap: () {},
                      ),
                      SettingsRow(
                        icon: Icons.star_outline_rounded,
                        iconColor: const Color(0xFF4A9EFF),
                        iconBgColor: const Color(0xFF1e2d4a),
                        label: 'Rate the App',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // permissions
                  SettingsSection(
                    label: 'Permissions',
                    rows: [
                      SettingsRow(
                        icon: Icons.phone_android_rounded,
                        iconColor: AppColors.success,
                        iconBgColor: const Color(0xFF1a2e1a),
                        label: 'Usage Access',
                        onTap: notifier.requestUsagePermission,
                        trailing: _permissionBadge(
                          state.hasUsagePermission,
                        ),
                      ),
                      SettingsRow(
                        icon: Icons.layers_outlined,
                        iconColor: AppColors.success,
                        iconBgColor: const Color(0xFF1a2e1a),
                        label: 'Display Over Apps',
                        onTap: notifier.requestOverlayPermission,
                        trailing: _permissionBadge(
                          state.hasOverlayPermission,
                        ),
                      ),
                      SettingsRow(
                        icon: Icons.battery_charging_full_rounded,
                        iconColor: AppColors.success,
                        iconBgColor: const Color(0xFF1a2e1a),
                        label: 'Battery Optimization',
                        onTap: notifier.requestBatteryOptimization,
                        trailing: _permissionBadge(
                          state.hasBatteryOptimization,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // account
                  SettingsSection(
                    label: 'Account',
                    rows: [
                      SettingsRow(
                        icon: Icons.settings_outlined,
                        iconColor: AppColors.gold,
                        iconBgColor: const Color(0xFF1e2530),
                        label: 'Manage Subscription',
                        onTap: () {},
                      ),
                      SettingsRow(
                        icon: Icons.restore_rounded,
                        iconColor: AppColors.gold,
                        iconBgColor: const Color(0xFF1e2530),
                        label: 'Restore Purchases',
                        onTap: notifier.restorePurchases,
                      ),
                      SettingsRow(
                        icon: Icons.refresh_rounded,
                        iconColor: AppColors.gold,
                        iconBgColor: const Color(0xFF1e2530),
                        label: 'Reset Daily Record',
                        onTap: () => _confirmReset(
                          context,
                          notifier.resetDailyRecord,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // legal
                  SettingsSection(
                    label: 'Legal',
                    rows: [
                      SettingsRow(
                        icon: Icons.description_outlined,
                        iconColor: AppColors.textSecondary,
                        iconBgColor: AppColors.backgroundSubtle,
                        label: 'Terms of Use',
                        onTap: () {},
                      ),
                      SettingsRow(
                        icon: Icons.shield_outlined,
                        iconColor: AppColors.textSecondary,
                        iconBgColor: AppColors.backgroundSubtle,
                        label: 'Privacy Policy',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // version
                  Center(
                    child: Text(
                      'APP VERSION: ${state.appVersion}',
                      style: AppTextStyles.bodySmall.copyWith(
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text('Settings', style: AppTextStyles.headlineMedium),
        ],
      ),
    );
  }

  // ── Permission badge ─────────────────────────────
  Widget _permissionBadge(bool granted) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: granted
            ? AppColors.success.withOpacity(0.15)
            : AppColors.error.withOpacity(0.15),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        granted ? 'Granted' : 'Required',
        style: AppTextStyles.bodySmall.copyWith(
          color: granted ? AppColors.success : AppColors.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Confirm reset dialog ─────────────────────────
  void _confirmReset(
      BuildContext context,
      VoidCallback onConfirm,
      ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Reset Daily Record?',
          style: AppTextStyles.headlineSmall,
        ),
        content: Text(
          'This will clear all usage data for today. This cannot be undone.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: Text(
              'Reset',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}