import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SettingsRow {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String label;
  final bool isDanger;
  final VoidCallback onTap;
  final Widget? trailing;

  const SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.label,
    required this.onTap,
    this.isDanger = false,
    this.trailing,
  });
}

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.label,
    required this.rows,
  });

  final String label;
  final List<SettingsRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.1,
              fontSize: 14
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border,
              width: 0.5,
            ),
          ),
          child: Column(
            children: List.generate(rows.length, (index) {
              final row = rows[index];
              final isLast = index == rows.length - 1;
              return Column(
                children: [
                  _buildRow(row),
                  if (!isLast)
                    Divider(
                      height: 0.5,
                      thickness: 0.5,
                      color: AppColors.border,
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(SettingsRow row) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: row.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 20,
          ),
          child: Row(
            children: [
              _buildIcon(row),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  row.label,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: row.isDanger
                        ? AppColors.error
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              row.trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(SettingsRow row) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: row.iconBgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        row.icon,
        color: row.iconColor,
        size: 22,
      ),
    );
  }
}