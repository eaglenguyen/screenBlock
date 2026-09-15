import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widget/continue_button.dart';
import '../gauntlet_stones.dart';
import '../schedule_gauntlet_card.dart';
import '../schedule_gauntlet_state.dart';


class OnboardingGauntletEquipScreen extends StatefulWidget {
  final ScheduleGauntletState state;
  final ScheduleStone justFilled;
  final int stepNumber; // 1-4
  final bool showConfetti;
  final VoidCallback onContinue;

  const OnboardingGauntletEquipScreen({
    super.key,
    required this.state,
    required this.justFilled,
    required this.stepNumber,
    this.showConfetti = false,
    required this.onContinue,
  });

  @override
  State<OnboardingGauntletEquipScreen> createState() => _OnboardingGauntletEquipScreenState();
}

class _OnboardingGauntletEquipScreenState extends State<OnboardingGauntletEquipScreen> {
  ConfettiController? _confettiController;
  bool _showCard = false; // 👈 new


  bool get _isFirstEquip => widget.stepNumber == 1; // 👈 new

  @override
  void initState() {
    super.initState();
    if (widget.showConfetti) {
      _confettiController = ConfettiController(duration: const Duration(seconds: 2));
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _confettiController?.play();
      });
    }

    if (_isFirstEquip) { // 👈 new — only delay/animate on the first screen
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _showCard = true);
      });
    } else {
      _showCard = true; // 👈 new — every other screen shows the card immediately, no animation
    }
  }

  @override
  void dispose() {
    _confettiController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          if (_confettiController != null)
            ConfettiWidget(
              confettiController: _confettiController!,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              gravity: 0.3,
              colors: const [Color(0xFFEE8FA8), Color(0xFF7FB4E8), Color(0xFF7FC9BB), Color(0xFFB398E8), Color(0xFFF8D35A)],
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                children: [
                  const Spacer(),
                  Text(
                    widget.showConfetti ? 'Schedule complete! 🎉' : '${widget.stepNumber}/4 steps done',
                    style: GoogleFonts.poppins(color: const Color(0xFF4A3728), fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                  if (!widget.showConfetti) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${4 - widget.stepNumber} more to go!',
                      style: GoogleFonts.poppins(color: const Color(0xFFB08A5A), fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                  const SizedBox(height: 32),
                  _isFirstEquip // 👈 new — only the first screen gets the animated reveal treatment at all
                      ? (_showCard
                      ? TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      final dy = (1 - value) * -200;
                      return Opacity(
                        opacity: value.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(0, dy),
                          child: child,
                        ),
                      );
                    },
                    child: ScheduleGauntletCard(state: widget.state, justFilled: widget.justFilled),
                  )
                      : const SizedBox(height: 140))
                      : ScheduleGauntletCard(state: widget.state, justFilled: widget.justFilled), // 👈 new — every other screen: just render it plainly, no animation, no delay
                  const SizedBox(height: 28),
                  ScheduleGauntletStones(state: widget.state, justFilled: widget.justFilled,  isFinalStone: widget.showConfetti,),
                  const Spacer(),
                  OnboardingContinueButton(
                    label: widget.showConfetti ? 'Finish' : 'Continue',
                    onTap: widget.onContinue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}