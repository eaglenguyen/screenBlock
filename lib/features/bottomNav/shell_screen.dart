import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  int _selectedIndex = 0;

  int _getIndexFromLocation(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/schedule')) return 1;
    if (location.startsWith('/stats')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  final List<String> _routes = [
    '/home',
    '/schedule',
    '/stats',
    '/settings',
  ];

  void _onNavTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    GoRouter.of(context).go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    _selectedIndex = _getIndexFromLocation(
      GoRouterState.of(context).uri.toString(),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          widget.child, // current tab screen renders here
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: AppColors.border,
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min, // 👈 key — pill shrinks to content
            children: [
              _navBtn(0, Icons.home_rounded),
              _navBtn(1, Icons.calendar_today_rounded),
              _navBtn(2, Icons.bar_chart_rounded),
              _navBtn(3, Icons.settings_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navBtn(int index, IconData icon) {
    final isActive = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () => _onNavTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.gold
                : AppColors.backgroundSubtle,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 28,
            color: isActive
                ? AppColors.goldText
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}