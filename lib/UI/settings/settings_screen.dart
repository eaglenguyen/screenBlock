import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:pausenow/UI/settings/settings_viewmodel.dart';
import 'package:pausenow/UI/settings/widgets/acknowledgements_sheet.dart';
import 'package:pausenow/UI/settings/widgets/profile_card.dart';
import 'package:pausenow/UI/settings/widgets/settings_section.dart';
import 'package:pausenow/UI/settings/widgets/support_sheets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.notifier.dart';
import '../../providers/blocking_service_provider.dart';
import '../../providers/premium_provider.dart';
import '../stats/widgets/goal_settings_sheet.dart';

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
                          onTap: () => context.push('/paywall', extra: 'settings_upgrade'), // 👈
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
                        icon: Icons.star_outline_rounded,
                        iconColor: AppColors.gold(context),
                        iconBgColor: AppColors.primarySubtle(context),
                        label: 'Rate the App  🙏',
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
                        },
                      ),
                      SettingsRow(
                        icon: Icons.chat_bubble_outline_rounded,
                        iconColor: AppColors.gold(context),
                        iconBgColor: AppColors.primarySubtle(context),
                        label: 'Give Feedback',
                        onTap: () => GiveFeedbackSheet.show(context), // 👈
                      ),
                      SettingsRow(
                        iconAsset: "assets/icons/mascot_face.png",
                        iconColor: AppColors.gold(context),
                        iconBgColor: Colors.transparent,
                        label: 'Get Help',
                        onTap: () => GetHelpSheet.show(context), // 👈
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // permissions
                  SettingsSection(
                    label: 'Permissions',
                    rows: [
                      SettingsRow(
                        icon: Icons.notifications_rounded,
                        iconColor: AppColors.gold(context),
                        iconBgColor: AppColors.primarySubtle(context),
                        label: 'Notifications',
                        onTap: () async {
                          if (Platform.isIOS) {
                            await openAppSettings();
                          } else {
                            final androidPlugin = FlutterLocalNotificationsPlugin()
                                .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
                            final granted = await androidPlugin?.areNotificationsEnabled() ?? false;
                            if (!granted) {
                              await notifier.requestNotificationPermission();
                            } else {
                              await openAppSettings(); // 👈 opens app settings where notifications toggle is
                            }
                          }
                          await notifier.checkPermissions();
                        },
                        trailing: _batteryBadge(state.hasNotificationPermission, context),
                      ),
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
                        icon: Icons.track_changes_rounded,
                        iconColor: AppColors.gold(context),
                        iconBgColor: AppColors.primarySubtle(context),
                        label: 'Goals',
                        onTap: () => GoalSettingsSheet.show(context, ref),
                      ),
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
                      SettingsRow(
                        icon: Icons.delete_outline_rounded,
                        iconColor: AppColors.error(context),
                        iconBgColor: AppColors.error(context).withValues(alpha: 0.1),
                        label: 'Delete Account',
                        isDanger: true,
                        onTap: () => _showDeleteAccountDialog(context),
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
                  // if (kDebugMode) ...[
                  //   const SizedBox(height: 8),
                  //   SettingsSection(
                  //     label: '🛠 Debug',
                  //     rows: [
                  //       SettingsRow(
                  //         icon: Icons.star_rounded,
                  //         iconColor: Colors.purple,
                  //         iconBgColor: Colors.purple.withValues(alpha: 0.1),
                  //         label: 'Force Premium',
                  //         onTap: () {},
                  //         trailing: Switch(
                  //           value: debugPremiumOverride,
                  //           onChanged: (val) {
                  //             debugPremiumOverride = val;
                  //             ref.invalidate(isPremiumProvider); // 👈 force rebuild
                  //           },
                  //           activeColor: AppColors.gold(context),
                  //           activeTrackColor: AppColors.gold(context).withValues(alpha: 0.3),
                  //           inactiveThumbColor: AppColors.textSecondary(context),
                  //           inactiveTrackColor: AppColors.backgroundSubtle(context),
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ],


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

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(
              'pause now does not store accounts',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'To delete all your data, simply uninstall the app from your device!',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold(context),
                foregroundColor: AppColors.goldText(context),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const StadiumBorder(),
              ),
              child: const Text('Okay'),
            ),
          ),
        ],
      ),
    );
  }

}