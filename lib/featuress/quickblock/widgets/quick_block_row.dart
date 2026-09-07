// lib/featuress/quickblock/widgets/quick_block_row.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../quick_block_viewmodel.dart';

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

class QuickBlockRow extends ConsumerWidget {
  const QuickBlockRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = ref.watch(quickBlockViewModelProvider);
    final notifier = ref.read(quickBlockViewModelProvider.notifier);

    return Row(
      children: quickBlockApps.map((app) {
        final isBlocked = blocked.contains(app.packageName);
        return Expanded(
          child: GestureDetector(
            onTap: () => notifier.toggle(app.packageName),
            child: SizedBox(
              height: 120,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8), // 👈 reserves room for the lip so it doesn't get clipped by the fixed height
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: 4,
                            left: 6,
                            right: 6,
                            bottom: -8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.cardLip(context),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                          Container(
                            width: double.infinity, // 👈 forces full width
                            height: 112, // 👈 forces explicit height instead of shrinking to content
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: app.bgColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
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
                        ],
                      ),
                    ),
                    if (isBlocked)
                      Positioned.fill(
                        child: Align(
                          alignment: const Alignment(0, -0.7),
                          child: Icon(Icons.close_rounded, color: AppColors.error(context), size: 60),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}