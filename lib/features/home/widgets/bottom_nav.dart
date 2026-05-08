// ── Bottom nav ───────────────────────────────────
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';


class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({super.key});


@override
Widget build(BuildContext context) {
  return Positioned(
    bottom: 16,
    left: 12,
    right: 12,
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8, vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(
            context,
            icon: Icons.home_rounded,
            label: 'Home',
            route: '/home',
            isActive: true,
          ),
          _navItem(
            context,
            icon: Icons.calendar_today_rounded,
            label: 'Schedule',
            route: '/schedule',
          ),
          _navItem(
            context,
            icon: Icons.bar_chart_rounded,
            label: 'Stats',
            route: '/stats',
          ),
          _navItem(
            context,
            icon: Icons.settings_rounded,
            label: 'Settings',
            route: '/settings',
          ),
        ],
      ),
    ),
  );
}

  Widget _navItem(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String route,
        bool isActive = false,
      }) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive
                ? AppColors.gold
                : AppColors.textSecondary,
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: isActive
                  ? AppColors.gold
                  : AppColors.textSecondary,
              fontWeight: isActive
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
}
}