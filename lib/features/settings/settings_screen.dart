import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:pausenow/features/settings/settings_viewmodel.dart';
import 'package:pausenow/features/settings/widgets/acknowledgements_sheet.dart';
import 'package:pausenow/features/settings/widgets/profile_card.dart';
import 'package:pausenow/features/settings/widgets/settings_section.dart';
import 'package:pausenow/features/settings/widgets/support_sheets.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/hivebox_names.dart';
import '../../core/theme/theme.notifier.dart';
import '../../providers/blocking_service_provider.dart';
import '../../providers/premium_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsViewModelProvider);
    final notifier = ref.read(settingsViewModelProvider.notifier);
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const SettingsProfileCard(),
                  const SizedBox(height: 12),

                  // Pro in Settings
                  if (!ref.watch(isPremiumProvider))
                    SettingsSection(
                      label: '',
                      rows: [
                        SettingsRow(
                          icon: Icons.bolt_rounded,
                          iconColor: const Color(0xFF1A1208),
                          iconBgColor: const Color(0xFFEDB82A),
                          label: 'Upgrade to Pro',
                          onTap: () => context.push('/paywall'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDB82A),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'PRO',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF1A1208),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (!ref.watch(isPremiumProvider)) const SizedBox(height: 20),

                  // appearance
                  SettingsSection(
                    label: 'Appearance',
                    rows: [
                      SettingsRow(
                        icon: isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        iconColor: AppColors.gold(context),
                        iconBgColor: AppColors.primarySubtle(context),
                        label: isDark ? 'Dark Mode' : 'Light Mode',
                        onTap: () => ref.read(themeProvider.notifier).toggle(),
                        trailing: Switch(
                          value: isDark,
                          onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
                          activeColor: AppColors.gold(context),
                          activeTrackColor: AppColors.gold(context).withValues(alpha: 0.3),
                          inactiveThumbColor: AppColors.textSecondary(context),
                          inactiveTrackColor: AppColors.backgroundSubtle(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // support
                  SettingsSection(
                    label: 'Support',
                    rows: [
                      SettingsRow(
                        icon: Icons.help_outline_rounded,
                        iconColor: AppColors.gold(context),
                        iconBgColor: AppColors.primarySubtle(context),
                        label: 'FAQS',
                        onTap: () => GetHelpSheet.show(context), // 👈
                      ),
                      SettingsRow(
                        icon: Icons.chat_bubble_outline_rounded,
                        iconColor: AppColors.gold(context),
                        iconBgColor: AppColors.primarySubtle(context),
                        label: 'Give Feedback',
                        onTap: () => GiveFeedbackSheet.show(context), // 👈
                      ),
                      SettingsRow(
                        icon: Icons.star_outline_rounded,
                        iconColor: AppColors.gold(context),
                        iconBgColor: AppColors.primarySubtle(context),
                        label: 'Rate the App',
                        onTap: () async {
                          final inAppReview = InAppReview.instance;
                          if (await inAppReview.isAvailable()) {
                            inAppReview.requestReview();
                          } else {
                            // fallback — open App Store page directly
                            inAppReview.openStoreListing(
                              appStoreId: '6781065557', // 👈 add once app is live
                            );
                          }
                        },                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // permissions
                  SettingsSection(
                    label: 'Permissions',
                    rows: [
                      if (Platform.isIOS)
                        SettingsRow(
                          icon: Icons.screen_lock_portrait_rounded,
                          iconColor: AppColors.success(context),
                          iconBgColor: AppColors.primarySubtle(context),
                          label: 'Screen Time Access',
                          onTap: () async {
                            final service = ref.read(blockingServiceProvider);
                            await service.requestAccessibilityPermission();
                            await notifier.checkPermissions();
                          },
                          trailing: _permissionBadge(state.hasScreenTimePermission, context),
                        ),
                      if (Platform.isAndroid)
                        SettingsRow(
                          icon: Icons.accessibility_new_rounded, // 👈 add this
                          iconColor: AppColors.success(context),
                          iconBgColor: AppColors.primarySubtle(context),
                          label: 'Accessibility',
                          onTap: notifier.requestAccessibilityPermission, // 👈 add this method to notifier
                          trailing: _permissionBadge(state.hasAccessibilityPermission, context),
                        ),
                      if (Platform.isAndroid)
                        SettingsRow(
                          icon: Icons.phone_android_rounded,
                          iconColor: AppColors.success(context),
                          iconBgColor: AppColors.primarySubtle(context),
                          label: 'Usage Access',
                          onTap: notifier.requestUsagePermission,
                          trailing: _permissionBadge(state.hasUsagePermission, context),
                        ),
                      if (Platform.isAndroid)
                        SettingsRow(
                          icon: Icons.layers_outlined,
                          iconColor: AppColors.success(context),
                          iconBgColor: AppColors.primarySubtle(context),
                          label: 'Display Over Apps',
                          onTap: notifier.requestOverlayPermission,
                          trailing: _permissionBadge(state.hasOverlayPermission, context),
                        ),
                      if (Platform.isAndroid)
                        SettingsRow(
                          icon: Icons.battery_charging_full_rounded,
                          iconColor: AppColors.gold(context),
                          iconBgColor: AppColors.primarySubtle(context),
                          label: 'Battery Optimization',
                          onTap: notifier.requestBatteryOptimization,
                          trailing: _batteryBadge(state.hasBatteryOptimization, context),
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
                        iconColor: AppColors.gold(context),
                        iconBgColor: AppColors.primarySubtle(context),
                        label: 'Manage Subscription',
                        onTap: () => launchUrl(
                          Uri.parse(
                            Platform.isIOS
                                ? 'https://apps.apple.com/account/subscriptions'
                                : 'https://play.google.com/store/account/subscriptions?sku=com.eagle.pausenow.monthly&package=com.eagle.pausenow',
                          ),
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                      SettingsRow(
                        icon: Icons.restore_rounded,
                        iconColor: AppColors.gold(context),
                        iconBgColor: AppColors.primarySubtle(context),
                        label: 'Restore Purchases',
                        onTap: () {
                          notifier.restorePurchases().then((_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ref.read(isPremiumProvider)
                                        ? 'Purchases restored! ✅'
                                        : 'No purchases found to restore.',
                                    style: TextStyle(color: AppColors.textPrimary(context)), // 👈 add this
                                  ),
                                  backgroundColor: AppColors.backgroundCard(context),
                                ),
                              );
                            }
                          });
                        },
                      ),
                      SettingsRow(
                        icon: Icons.refresh_rounded,
                        iconColor: AppColors.gold(context),
                        iconBgColor: AppColors.primarySubtle(context),
                        label: 'Reset Time Blocked',
                        onTap: () => _confirmReset(context, notifier.resetDailyRecord),
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
                        iconColor: AppColors.textSecondary(context),
                        iconBgColor: AppColors.backgroundSubtle(context),
                        label: 'Terms of Use',
                        onTap: () => launchUrl(
                          Uri.parse('https://eaglenguyen.github.io/pausenow-legal/terms_of_service'),
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                      SettingsRow(
                        icon: Icons.shield_outlined,
                        iconColor: AppColors.textSecondary(context),
                        iconBgColor: AppColors.backgroundSubtle(context),
                        label: 'Privacy Policy',
                        onTap: () => launchUrl(
                          Uri.parse('https://eaglenguyen.github.io/pausenow-legal/privacy_policy'),
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                      SettingsRow( // 👈 add this
                        icon: Icons.favorite_outline_rounded,
                        iconColor: AppColors.textSecondary(context),
                        iconBgColor: AppColors.backgroundSubtle(context),
                        label: 'Acknowledgments',
                        onTap: () => AcknowledgmentsSheet.show(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 👇 debug section — only shows in debug mode
                  if (kDebugMode) ...[
                    const SizedBox(height: 8),
                    SettingsSection(
                      label: '🛠 Debug',
                      rows: [
                        SettingsRow(
                          icon: Icons.star_rounded,
                          iconColor: Colors.purple,
                          iconBgColor: Colors.purple.withValues(alpha: 0.1),
                          label: 'Force Premium',
                          onTap: () {},
                          trailing: Switch(
                            value: debugPremiumOverride,
                            onChanged: (val) {
                              debugPremiumOverride = val;
                              ref.invalidate(isPremiumProvider); // 👈 force rebuild
                            },
                            activeColor: AppColors.gold(context),
                            activeTrackColor: AppColors.gold(context).withValues(alpha: 0.3),
                            inactiveThumbColor: AppColors.textSecondary(context),
                            inactiveTrackColor: AppColors.backgroundSubtle(context),
                          ),
                        ),
                        SettingsRow(
                          icon: Icons.restart_alt_rounded,
                          iconColor: Colors.red,
                          iconBgColor: Colors.red.withValues(alpha: 0.1),
                          label: 'Reset Onboarding',
                          onTap: () async {
                            final box = Hive.box(HiveBoxNames.settings);
                            await box.put('onboardingComplete', false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Onboarding reset — restart app')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],


                  Center(
                    child: Text(
                      'APP VERSION: ${state.appVersion}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary(context),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
      child: Center(
        child: Text(
          'Settings',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textPrimary(context),
          ),
        ),
      ),
    );
  }

  Widget _permissionBadge(bool granted, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: granted
            ? AppColors.success(context).withValues(alpha: 0.15)
            : AppColors.error(context).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        granted ? 'Granted' : 'Required',
        style: AppTextStyles.bodySmall.copyWith(
          color: granted ? AppColors.success(context) : AppColors.error(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _batteryBadge(bool granted, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: granted
            ? AppColors.success(context).withValues(alpha: 0.15)
            : AppColors.gold(context).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        granted ? 'Enabled' : 'Optional',
        style: AppTextStyles.bodySmall.copyWith(
          color: granted
              ? AppColors.success(context)
              : AppColors.gold(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reset Daily Record?',
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary(context)),
        ),
        content: Text(
          'This will clear all usage data for today. This cannot be undone.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context)),
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
                color: AppColors.error(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}