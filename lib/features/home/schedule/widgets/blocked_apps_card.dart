import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/platform/ios_blocking_service.dart';
import '../../../../providers/blocking_service_provider.dart';
import '../../../home/widgets/app_list_sheet.dart';

import '../../home_viewmodel.dart';

class BlockedAppsCard extends ConsumerWidget {
  const BlockedAppsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeViewModelProvider);
    final blockedCount = homeState.blockedApps.length;
    final allowedCount = homeState.allowedApps.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Blocked Apps',
                  style: AppTextStyles.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Apps blocked or allowed during sessions,\ndepending on Session Type',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),

          const Divider(
            height: 0.5,
            thickness: 0.5,
            color: AppColors.border,
          ),

          _listRow(
            context,
            ref,
            emoji: '🔒',
            title: 'Block List',
            subtitle:
            "When Session Type is 'Specific Apps', only these apps will be blocked",
            count: blockedCount,
            onTap: () => _openAppSheet(
              context,
              ref,
              isBlockList: true,
              initialApps: homeState.blockedApps,
            ),
          ),

          const Divider(
            height: 0.5,
            thickness: 0.5,
            color: AppColors.border,
            indent: 16,
            endIndent: 16,
          ),

          _listRow(
            context,
            ref,
            emoji: '👍',
            title: 'Allow List',
            subtitle:
            "When Session Type is 'All Apps', all apps except these will be blocked",
            count: allowedCount,
            onTap: () => _openAppSheet(
              context,
              ref,
              isBlockList: false,
              initialApps: homeState.allowedApps,
            ),
          ),
        ],
      ),
    );
  }
  void _openAppSheet(
      BuildContext context,
      WidgetRef ref, {
        required bool isBlockList,
        required List<String> initialApps,
      }) {
    final notifier = ref.read(homeViewModelProvider.notifier);

    if (Platform.isIOS) {
      _showIOSAppPicker(
        context,
        ref,
        isBlockList: isBlockList,
        notifier: notifier,
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useRootNavigator: true,
        builder: (_) => AppListSheet(
          isBlockList: isBlockList,
          initialApps: initialApps,
          onSave: (apps) {
            if (isBlockList) {
              notifier.setBlockedApps(apps);
            } else {
              notifier.setAllowedApps(apps);
            }
          },
        ),
      );
    }
  }

  Future<void> _showIOSAppPicker(
      BuildContext context,
      WidgetRef ref, {
        required bool isBlockList,
        required HomeViewModel notifier,
      }) async {
    try {
      final service = ref.read(blockingServiceProvider)
      as IOSBlockingService;

      final count = await service.showAppPicker(
        blockingMode: isBlockList
            ? AppConstants.blockingTypeSpecificApps
            : AppConstants.blockingTypeAllApps,
      );

      if ((count ?? 0) > 0) {
        final placeholders = List.generate(
          count!,
              (i) => 'ios_app_$i',
        );
        if (isBlockList) {
          notifier.setBlockedApps(placeholders);
        } else {
          notifier.setAllowedApps(placeholders);
        }
      }
    } catch (e) {
      debugPrint('❌ iOS app picker error: $e');
    }
  }

  Widget _listRow(
      BuildContext context,
      WidgetRef ref, {
        required String emoji,
        required String title,
        required String subtitle,
        required int count,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTextStyles.labelMedium
                      .copyWith(fontSize: 16),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      '$count',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: AppTextStyles.bodySmall),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.backgroundSubtle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border,
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    count > 0
                        ? '$count app${count == 1 ? '' : 's'} selected'
                        : title == 'Block List'
                        ? 'No apps blocked'
                        : 'No apps allowed',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: count > 0
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.apps_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}