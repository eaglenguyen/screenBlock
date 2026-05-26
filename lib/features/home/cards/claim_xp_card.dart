import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ClaimXpCard extends StatefulWidget {
  const ClaimXpCard({
    super.key,
    required this.xpEarned,
    required this.sessionMinutes,
    required this.todayBlocked,
    required this.totalXp,
    required this.onClaim,
  });

  final int xpEarned;
  final int sessionMinutes;
  final String todayBlocked;
  final int totalXp;
  final VoidCallback onClaim;

  @override
  State<ClaimXpCard> createState() => _ClaimXpCardState();
}

class _ClaimXpCardState extends State<ClaimXpCard>
    with SingleTickerProviderStateMixin {

  late ConfettiController _confettiController;
  late AnimationController _controller;
  late Animation<double> _bounceAnim;

  bool _claiming = false;
  int _displayXp = 0;

  @override
  void initState() {
    super.initState();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _bounceAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
      _controller.forward();

      // haptic burst
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 100), () {
        HapticFeedback.mediumImpact();
      });
      Future.delayed(const Duration(milliseconds: 200), () {
        HapticFeedback.lightImpact();
      });
    });

  }

  @override
  void dispose() {
    _confettiController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onClaimTapped() async {
    if (_claiming) return;
    setState(() => _claiming = true);

    // haptic + count up animation
    final total = widget.xpEarned;
    final steps = total.clamp(1, 30); // max 30 ticks
    final interval = Duration(
      milliseconds: (1200 / steps).round(),
    );

    for (int i = 1; i <= steps; i++) {
      await Future.delayed(interval);
      if (!mounted) return;
      setState(() {
        _displayXp = ((total * i) / steps).round();
      });
      // haptic tick
      HapticFeedback.lightImpact();
    }

    // final heavy haptic
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 200));

    widget.onClaim();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // confetti
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: 30,
          gravity: 0.3,
          emissionFrequency: 0.05,
          blastDirection: pi / 2,
          colors: const [
            AppColors.gold,
            Color(0xFFFF6B6B),
            Color(0xFF4ECDC4),
            Color(0xFF45B7D1),
            Color(0xFF96CEB4),
            Color(0xFFFF9F43),
          ],
        ),

        // main content
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // bolt icon
              ScaleTransition(
                scale: _bounceAnim,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: AppColors.goldText,
                    size: 48,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Session complete!',
                style: AppTextStyles.headlineMedium
                    .copyWith(fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                'Great job staying present',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      label: 'XP this session',
                      value: _claiming
                          ? '$_displayXp'
                          : '${widget.xpEarned}',
                      icon: Icons.bolt_rounded,
                      iconColor: AppColors.gold,
                      highlight: _claiming,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      label: 'Total XP',
                      value: _claiming
                          ? '${widget.totalXp + _displayXp}'
                          : '${widget.totalXp + widget.xpEarned}',
                      icon: Icons.stars_rounded,
                      iconColor: AppColors.gold,
                      highlight: _claiming,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      label: 'Time blocked',
                      value: '${widget.sessionMinutes}m',
                      icon: Icons.timer_rounded,
                      iconColor: AppColors.gold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      label: "Today's total",
                      value: widget.todayBlocked,
                      icon: Icons.lock_clock_rounded,
                      iconColor: AppColors.gold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _claiming ? null : _onClaimTapped,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _claiming
                        ? AppColors.backgroundSubtle
                        : AppColors.gold,
                    foregroundColor: AppColors.goldText,
                    disabledBackgroundColor:
                    AppColors.backgroundSubtle,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: AppTextStyles.labelLarge,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bolt_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _claiming
                            ? 'Claiming...'
                            : 'Claim ${widget.xpEarned} XP',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    bool fullWidth = false,
    bool highlight = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.gold.withValues(alpha: 0.1)
            : AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight
              ? AppColors.gold.withValues(alpha: 0.3)
              : AppColors.border,
          width: highlight ? 1 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Text(
                value,
                style: AppTextStyles.headlineSmall.copyWith(
                  fontSize: 18,
                  color: highlight ? AppColors.gold : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}