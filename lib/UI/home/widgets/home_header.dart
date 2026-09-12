import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../home_state.dart';


class HomeHeader extends StatelessWidget {

  final HomeState state;
  final GlobalKey? xpBadgeKey;


  const HomeHeader({
    super.key,
    required this.state,
    this.xpBadgeKey, 

  });



  @override
  Widget build(BuildContext context) {
  return Container(
    padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
    decoration:  BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF252015)
              : AppColors.backgroundCard(context),
          AppColors.background(context),
        ],
      ),
    ),
    child: Row(
      children: [
        Text(
          state.pomodoroConfig.isPomodoroMode ? 'Pomodoro Session' : 'Focus Session', // 👈 was Text('Focus Session', ...)
          style: AppTextStyles.headlineMedium,
        ),        const Spacer(),
        _buildXpBadge(state, context),
      ],
    ),
  );
}




  Widget _buildXpBadge(HomeState state, BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.backgroundCard(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Text(
                  '⭐️ Stats',
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Coming soon',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accent(context).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: AppColors.accent(context).withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '1 minute = 1 ⭐️',
                        style: TextStyle(
                          color: AppColors.accent(context),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              Center( // 👈 new — centers the circle since it's no longer full-width
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: 56, // 👈 new — replaces the stadium button's dimensions
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.accent(context),
                      shape: BoxShape.circle, // 👈 was StadiumBorder()
                    ),
                    child: const Center(
                      child: Text(
                        '👌🏾',
                        style: TextStyle(fontSize: 26), // 👈 slightly adjusted to fit the circle nicely
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: _badge(
        key: xpBadgeKey,
        context: context,
        child: Row(
          children: [
            Text('',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.accent(context),
              ),
            ),
            const SizedBox(width: 5),
            Text('${state.totalXp} ⭐️', style: AppTextStyles.labelMedium),
          ],
        ),
      ),
    );
  }

  Widget _badge({required Widget child, Key? key, required BuildContext context}) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(
        horizontal: 14, vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard(context),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: child,
    );
  }
}
