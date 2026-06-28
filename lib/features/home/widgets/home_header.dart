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
        const Spacer(),
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
                    color: AppColors.gold(context).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: AppColors.gold(context).withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '1 minute = 5 ⭐️',
                        style: TextStyle(
                          color: AppColors.gold(context),
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold(context),
                    foregroundColor: AppColors.goldText(context),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('👌🏾',
                      style: TextStyle(fontWeight: FontWeight.w700,
                      fontSize: 25)
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
                color: AppColors.gold(context),
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
