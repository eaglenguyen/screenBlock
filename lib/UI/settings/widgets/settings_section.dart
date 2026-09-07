import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SettingsRow {
  final IconData? icon;
  final String? iconAsset;     // 👈 add this
  final Color iconColor;
  final Color iconBgColor;
  final String label;
  final bool isDanger;
  final VoidCallback onTap;
  final Widget? trailing;

  const SettingsRow({
    this.icon,
    this.iconAsset,
    required this.iconColor,
    required this.iconBgColor,
    required this.label,
    required this.onTap,
    this.isDanger = false,
    this.trailing,
  }): assert(icon != null || iconAsset != null, 'Provide either icon or iconAsset');
}

class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, required this.label, required this.rows, this.labelFlair});

  final String label;
  final List<SettingsRow> rows;
  final String? labelFlair;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textPrimary(context),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        // 👇 REPLACE FROM HERE...
        Stack(
          clipBehavior: Clip.none, // 👈 required — lets the back layer render outside the front card's bounds
          children: [
            Positioned(
              top: 6,
              left: 4,
              right: 4,
              bottom: -8,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardLip(context), // 👈 was the raw hex
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundCard(context),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: List.generate(rows.length, (index) {
                  final row = rows[index];
                  final isLast = index == rows.length - 1;
                  return Column(
                    children: [
                      _buildRow(row, context),
                      if (!isLast)
                        Divider(height: 0.5, thickness: 0.5, color: AppColors.border(context), indent: 60, endIndent: 16),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(SettingsRow row, BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: row.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              _buildIcon(row),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  row.label,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: row.isDanger ? AppColors.error(context) : AppColors.textPrimary(context),
                  ),
                ),
              ),
              row.trailing ?? Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary(context), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(SettingsRow row) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: row.iconBgColor,
        shape: BoxShape.circle, // was rounded rect
      ),
      child: row.iconAsset != null
          ? ClipOval(child: Image.asset(row.iconAsset!, width: 34, height: 34, fit: BoxFit.cover))
          : Icon(row.icon!, color: row.iconColor, size: 18),
    );
  }
}