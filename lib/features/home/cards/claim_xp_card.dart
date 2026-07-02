import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
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
  late AudioPlayer _successPlayer;
  late AudioPlayer _tickPlayer;

  bool _claiming = false;
  int _displayXp = 0;

  @override
  void initState() {
    super.initState();
    _displayXp = widget.totalXp;

    _successPlayer = AudioPlayer();
    _tickPlayer = AudioPlayer();

    _tickPlayer.setAsset('assets/sounds/powerup1.mp3').then((_) {
      _tickPlayer.setVolume(0.5);
    });


    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
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
      _playSuccessSound();

      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 100), () {
        HapticFeedback.mediumImpact();
      });
      Future.delayed(const Duration(milliseconds: 200), () {
        HapticFeedback.lightImpact();
      });
    });
  }

  Future<void> _playSuccessSound() async {
    try {
      await _successPlayer.setAsset('assets/sounds/confetti.mp3');
      await _successPlayer.setVolume(0.8);
      await _successPlayer.play();
    } catch (e) {
      debugPrint('❌ success sound error: $e');
    }
  }


  @override
  void dispose() {
    _successPlayer.dispose();
    _tickPlayer.dispose();
    _confettiController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onClaimTapped() async {
    if (_claiming) return;
    setState(() => _claiming = true);

    // play tick once at start
    try {
      await _tickPlayer.seek(Duration.zero);
      _tickPlayer.play();
    } catch (_) {}

    final startXp = widget.totalXp; // 30
    final earnedXp = widget.xpEarned; // 10
    final finalTotal = startXp + earnedXp;

    final steps = finalTotal.clamp(1, 30);
    final interval = Duration(
      milliseconds: (1200 / steps).round(),
    );

    for (int i = 1; i <= steps; i++) {
      await Future.delayed(interval);
      if (!mounted) return;
      setState(() {
        final progress = i / steps;
        _displayXp = startXp + ((finalTotal - startXp) * progress).round();
      });
      HapticFeedback.lightImpact();
      // no sound per tick
    }

    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 200));

    widget.onClaim();
  }
// ... rest of build method unchanged


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
          colors:  [
            AppColors.gold(context),
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
                  decoration:  BoxDecoration(
                    color: AppColors.gold(context),
                    shape: BoxShape.circle,
                  ),
                  child:  Icon(
                    Icons.bolt_rounded,
                    color: AppColors.goldText(context),
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
                  color: AppColors.textSecondary(context),
                ),
              ),

              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      label: '⭐️ this session',
                      value: '${widget.xpEarned}',
                      icon: Icons.star,
                      iconColor: AppColors.gold(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      label: 'Total ⭐️',
                      value: '$_displayXp',
                      icon: Icons.stars_rounded,
                      iconColor: AppColors.gold(context),
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
                      iconColor: AppColors.gold(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      label: "Today's total",
                      value: widget.todayBlocked,
                      icon: Icons.lock_clock_rounded,
                      iconColor: AppColors.gold(context),
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
                        ? AppColors.backgroundSubtle(context)
                        : AppColors.gold(context),
                    foregroundColor: AppColors.goldText(context),
                    disabledBackgroundColor:
                    AppColors.backgroundSubtle(context),
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
                      Text(
                        _claiming
                            ? 'Claiming...'
                            : 'Claim ${widget.xpEarned} ⭐️',
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
            ? AppColors.gold(context).withValues(alpha: 0.1)
            : AppColors.backgroundCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight
              ? AppColors.gold(context).withValues(alpha: 0.3)
              : AppColors.border(context),
          width: highlight ? 1 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary(context),
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
                  color: highlight ? AppColors.gold(context) : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}