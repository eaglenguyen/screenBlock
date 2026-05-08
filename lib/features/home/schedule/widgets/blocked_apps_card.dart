import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';


class BlockedAppsCard extends StatelessWidget {
  const BlockedAppsCard({super.key});

  @override
  Widget build(BuildContext context) {
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
          // header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16, 16, 16, 8,
            ),
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

          const Divider(height: 0.5, thickness: 0.5,
            color: AppColors.border,
          ),

          // block list row
          _listRow(
            context,
            emoji: '🔒',
            title: 'Block List',
            subtitle: "When Session Type is 'Specific Apps', only these apps will be blocked",
            onTap: () => context.push('/block-list'),
          ),

          const Divider(
            height: 0.5,
            thickness: 0.5,
            color: AppColors.border,
            indent: 16,
            endIndent: 16,
          ),

          // allow list row
          _listRow(
            context,
            emoji: '👍',
            title: 'Allow List',
            subtitle: "When Session Type is 'All Apps', all apps except these will be blocked",
            onTap: () => context.push('/allow-list'),
          ),
        ],
      ),
    );
  }

  Widget _listRow(
      BuildContext context, {
        required String emoji,
        required String title,
        required String subtitle,
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
                Text(emoji,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: AppTextStyles.bodySmall),
            const SizedBox(height: 10),
            // collapsed app preview row
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12,
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
                    title == 'Block List'
                        ? 'Blocked Apps'
                        : 'Allowed Apps',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
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