import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

const _pastelYellow = Color(0xFFFFE4A3);
const _pastelYellowText = Color(0xFF6B5417);

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
      curve: Curves.easeOutBack, // 👈 was Curves.elasticOut — matches tonight's standard bounce
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

    try {
      await _tickPlayer.seek(Duration.zero);
      _tickPlayer.play();
    } catch (_) {}

    final startXp = widget.totalXp;
    final earnedXp = widget.xpEarned;
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
    }

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
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: 30,
          gravity: 0.3,
          emissionFrequency: 0.05,
          blastDirection: pi / 2,
          colors: const [
            _pastelYellow, // 👈 was AppColors.accent(context)
            Color(0xFFFF6B6B),
            Color(0xFF4ECDC4),
            Color(0xFF45B7D1),
            Color(0xFF96CEB4),
            Color(0xFFFF9F43),
          ],
        ),

        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // bolt icon
              ScaleTransition(
                scale: _bounceAnim,
                child: Container(
                  width: 92, // 👈 was 88 — slightly bigger
                  height: 92,
                  decoration: BoxDecoration(
                    color: _pastelYellow, // 👈 was AppColors.accent(context)
                    shape: BoxShape.circle,
                    boxShadow: [ // 👈 new — soft glow, matches the other celebratory cards tonight
                      BoxShadow(color: _pastelYellow.withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 2),
                    ],
                  ),
                  child: Icon(
                    Icons.bolt_rounded,
                    color: _pastelYellowText, // 👈 was AppColors.accentText(context)
                    size: 48,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Text(
                'Great Focus!',
                style: AppTextStyles.headlineLarge.copyWith( // 👈 was headlineMedium — bigger
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary(context),
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
                      iconColor: _pastelYellowText, // 👈 was AppColors.accent(context)
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      label: 'Total ⭐️',
                      value: '$_displayXp',
                      icon: Icons.stars_rounded,
                      iconColor: _pastelYellowText, // 👈 was AppColors.accent(context)
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
                      iconColor: _pastelYellowText, // 👈 was AppColors.accent(context)
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      label: "Today's total",
                      value: widget.todayBlocked,
                      icon: Icons.lock_clock_rounded,
                      iconColor: _pastelYellowText, // 👈 was AppColors.accent(context)
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
                        : _pastelYellow, // 👈 was AppColors.accent(context)
                    foregroundColor: _pastelYellowText, // 👈 was AppColors.accentText(context)
                    disabledBackgroundColor: AppColors.backgroundSubtle(context),
                    padding: const EdgeInsets.symmetric(vertical: 18), // 👈 was 16 — taller
                    shape: const StadiumBorder(), // 👈 was RoundedRectangleBorder(16) — matches bubbly convention
                    elevation: 0,
                    textStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  child: Text(
                    _claiming
                        ? 'Claiming...'
                        : 'Claim ${widget.xpEarned} ⭐️',
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
            ? _pastelYellow.withValues(alpha: 0.15) // 👈 was AppColors.accent(context)
            : AppColors.backgroundCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight
              ? _pastelYellow.withValues(alpha: 0.5) // 👈 was AppColors.accent(context)
              : AppColors.border(context),
          width: highlight ? 1 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith( // 👈 was bodySmall — bumped up
              color: AppColors.textSecondary(context),
              fontWeight: FontWeight.w600,
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
                  fontSize: 19, // 👈 was 18 — slightly bigger
                  fontWeight: FontWeight.w800,
                  color: highlight ? _pastelYellowText : null, // 👈 was AppColors.accent(context)
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}