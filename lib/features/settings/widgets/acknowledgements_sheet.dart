import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AcknowledgmentsSheet {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _AcknowledgmentsSheet(),
    );
  }
}

class _AcknowledgmentsSheet extends StatelessWidget {
  const _AcknowledgmentsSheet();

  // ── Edit these with your actual asset details ──────
  static const String _assetName = '[Asset Name]';
  static const String _creatorName = '[Creator Name]';
  static const String _assetUrl = '[https://rive.app/...]';
  static const bool _wasModified = false; // set false if unmodified

  static const String _licenseUrl =
      'https://creativecommons.org/licenses/by/4.0/';

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24, 20, 24,
        MediaQuery.of(context).padding.bottom + 32,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppColors.textSecondary(context).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text(
            'Acknowledgments',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pause Now is built with the help of these creators.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 24),

          // ── Mascot attribution card ──────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.backgroundSubtle(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.border(context),
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mascot Illustration',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.gold(context),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '"$_assetName" by $_creatorName',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _wasModified
                      ? 'Modified for use in Pause Now. Licensed under CC BY 4.0.'
                      : 'Licensed under CC BY 4.0.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary(context),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),

                // links
                _LinkRow(
                  label: 'View original asset',
                  onTap: () => _openUrl(_assetUrl),
                  context: context,
                ),
                const SizedBox(height: 8),
                _LinkRow(
                  label: 'View CC BY 4.0 license',
                  onTap: () => _openUrl(_licenseUrl),
                  context: context,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // disclaimer
          Text(
            'All trademarks and assets belong to their respective owners. '
                'Attribution does not imply endorsement.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary(context).withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final BuildContext context;

  const _LinkRow({
    required this.label,
    required this.onTap,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            Icons.open_in_new_rounded,
            size: 16,
            color: AppColors.gold(context),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.gold(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}