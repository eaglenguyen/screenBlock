import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SessionCompletedCard extends StatefulWidget {
  const SessionCompletedCard({
    super.key,
    required this.selectedMinutes,
    required this.xpEarned,
    required this.onFinish,
  });

  final int selectedMinutes;
  final int xpEarned;
  final VoidCallback onFinish;

  @override
  State<SessionCompletedCard> createState() =>
      _SessionCompletedCardState();
}

class _SessionCompletedCardState
    extends State<SessionCompletedCard>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.border(context),
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // top section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
            decoration: BoxDecoration(
              color: AppColors.backgroundSubtle(context),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // animated star icon
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.gold(context)
                          .withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child:  Icon(
                      Icons.star_rounded,
                      color: AppColors.gold(context),
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Session Complete!',
                  style: AppTextStyles.headlineMedium
                      .copyWith(fontSize: 22),
                ),
                const SizedBox(height: 8),
                // timer at 00:00:00
                Text(
                  '00:00:00',
                  style: AppTextStyles.displayLarge
                      .copyWith(
                    fontSize: 48,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 12),
                // XP bar
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSubtle(context),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 1.0,
                      backgroundColor: Colors.transparent,
                      valueColor:
                       AlwaysStoppedAnimation(
                        AppColors.gold(context),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    Text(
                      '+ ${widget.xpEarned} ⭐️ earned',
                      style: AppTextStyles.bodySmall
                          .copyWith(
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // bottom section
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onFinish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold(context),
                  foregroundColor: AppColors.goldText(context),
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: AppTextStyles.labelLarge,
                ),
                child: const Text('🎉 Finish and Unblock'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}