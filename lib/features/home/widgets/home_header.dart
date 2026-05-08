import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../home_state.dart';


class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.state,
  });

  final HomeState state;


  @override
  Widget build(BuildContext context) {
  return Container(
    padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1a1a3e), AppColors.background],
      ),
    ),
    child: Row(
      children: [
        _buildAvatar(),
        const Spacer(),
        _buildStreakBadge(state),
        const SizedBox(width: 8),
        _buildXpBadge(state),
      ],
    ),
  );
}

Widget _buildAvatar() {
  return Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: AppColors.backgroundSubtle,
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.border),
    ),
    child: const Icon(
      Icons.person_outline_rounded,
      color: AppColors.textSecondary,
      size: 22,
    ),
  );
}

Widget _buildStreakBadge(HomeState state) {
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 12, vertical: 6,
    ),
    decoration: BoxDecoration(
      color: AppColors.backgroundCard,
      borderRadius: BorderRadius.circular(50),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        const Text('🔥', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          '${state.streak?.currentStreak ?? 0}',
          style: AppTextStyles.labelMedium,
        ),
      ],
    ),
  );
}

Widget _buildXpBadge(HomeState state) {
  return _badge(
    child: Row(
      children: [
        const Text('⚡',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(width: 5),
        Text('0 XP', style: AppTextStyles.labelMedium),
      ],
    ),
  );


}

  Widget _badge({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14, vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
