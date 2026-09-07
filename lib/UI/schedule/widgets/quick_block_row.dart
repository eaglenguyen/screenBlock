// lib/UI/schedule/widgets/quick_block_row.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class QuickBlockApp {
  final String name;
  final String iconAsset;
  final Color iconColor;
  final Color bgColor;
  final String packageName;

  const QuickBlockApp({
    required this.name,
    required this.iconAsset,
    required this.iconColor,
    required this.bgColor,
    required this.packageName,
  });
}

const quickBlockApps = [
  QuickBlockApp(name: 'TikTok', iconAsset: 'assets/icons/tiktok.svg', iconColor: Colors.white, bgColor: Color(0xFFDCEBFF), packageName: 'com.zhiliaoapp.musically'),
  QuickBlockApp(name: 'Instagram', iconAsset: 'assets/icons/instagram.svg', iconColor: Color(0xFFC2478B), bgColor: Color(0xFFFFE1EC), packageName: 'com.instagram.android'),
  QuickBlockApp(name: 'YouTube', iconAsset: 'assets/icons/youtube.svg', iconColor: Color(0xFFB07A1E), bgColor: Color(0xFFFFE8B8), packageName: 'com.google.android.youtube'),
];

class QuickBlockRow extends StatelessWidget {
  final Set<String> blockedPackages;
  final ValueChanged<String> onToggle;

  const QuickBlockRow({super.key, required this.blockedPackages, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: quickBlockApps.map((app) {
        final isBlocked = blockedPackages.contains(app.packageName);
        return Expanded(
          child: GestureDetector(
            onTap: () => onToggle(app.packageName),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isBlocked ? AppColors.error(context).withValues(alpha: 0.12) : app.bgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  SvgPicture.asset(app.iconAsset, width: 24, height: 24,
                      colorFilter: ColorFilter.mode(app.iconColor, BlendMode.srcIn)),
                  const SizedBox(height: 6),
                  Text(app.name, style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(
                    isBlocked ? 'Blocked' : 'Tap to block',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 9,
                      color: isBlocked ? AppColors.error(context) : AppColors.textSecondary(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}