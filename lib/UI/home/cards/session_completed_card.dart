import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/lipped_card.dart';

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
      duration: const Duration(milliseconds: 700), // 👈 was 600 — slightly longer for the bouncier curve
    );
    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack, // 👈 was Curves.elasticOut — matches tonight's standard bounce
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LippedCard( // 👈 was a plain Container — now uses the shared bubbly card treatment
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // top section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 36, 20, 28), // 👈 slightly roomier
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
                      width: 80, // 👈 was 72 — bigger
                      height: 80,
                      decoration: BoxDecoration(
                        color: Color(0xFFF7C948).withValues(alpha: 0.18),
                        shape: BoxShape.circle,

                        boxShadow: [ // 👈 new — soft glow, matches the celebratory tone
                          BoxShadow(color: Color(0xFFF7C948).withValues(alpha: 0.25), blurRadius: 16, spreadRadius: 2),
                        ],
                      ),
                      child: Icon(
                        Icons.star_rounded,
                        color: Color(0xFFF7C948),
                        size: 44, // 👈 was 40
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Session Complete!', // 👈 emoji added, matches the bubbly convention
                    style: AppTextStyles.headlineLarge.copyWith( // 👈 was headlineMedium — bigger
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  // timer at 00:00:00
                  Text(
                    '00:00:00',
                    style: AppTextStyles.displayLarge.copyWith(
                      fontSize: 48,
                      color: AppColors.textSecondary(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // XP bar
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard(context),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: LinearProgressIndicator(
                        value: 1.0,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation(
                          const Color(0xFFF7C948), // 👈 was AppColors.accent(context) — gold
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDB82A).withValues(alpha: 0.12), // 👈 was AppColors.accent(context)
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      '+ ${widget.xpEarned} ⭐️ earned',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: const Color(0xFFEDB82A), // 👈 was AppColors.accent(context)
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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
                    backgroundColor: const Color(0xFFFFE4A3), // 👈 was Color(0xFFF7C948) — softer, pastel yellow
                    foregroundColor: const Color(0xFF6B5417), // 👈 was Color(0xFF3D2E00) — warmer, less harsh dark tone
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: const StadiumBorder(),
                    elevation: 0,
                    textStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  child: const Text('🎉 Finish and Unblock'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}