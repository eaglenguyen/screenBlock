// lib/onboarding_new/screens/good_news_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widget/continue_button.dart';
import '../widget/slot_machine_animation.dart';

const Map<int, int> _screenTimeYearsPreset = {
  1: 2,
  2: 5,
  3: 7,
  4: 9,
  5: 11,
  6: 14,
  7: 16,
  8: 18,
  9: 21,
  10: 23,
  11: 25,
  12: 28,
};

class OnboardingGoodNewsScreen extends StatefulWidget {
  final double screenTimeHoursPerDay;
  final VoidCallback onContinue;

  const OnboardingGoodNewsScreen({
    super.key,
    required this.screenTimeHoursPerDay,
    required this.onContinue,
  });

  @override
  State<OnboardingGoodNewsScreen> createState() => _OnboardingGoodNewsScreenState();
}

class _OnboardingGoodNewsScreenState extends State<OnboardingGoodNewsScreen> with TickerProviderStateMixin {
  late AnimationController _revealController;


  int get _yearsReclaimed {
    final hours = widget.screenTimeHoursPerDay.round().clamp(1, 12);
    final lostYears = _screenTimeYearsPreset[hours] ?? 2;
    return (lostYears * 0.5).round().clamp(1, 99); // 👈 tune 0.5 — fraction of lost years reclaimed
  }

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(vsync: this, duration: const Duration(milliseconds: 4500));
    _revealController.forward();
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  Widget _staggeredRow({required Widget child, required double start, required double end}) {
    final fade = CurvedAnimation(parent: _revealController, curve: Interval(start, end, curve: Curves.easeOut));
    final slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(fade);
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            children: [
              const Spacer(flex: 3),
              _staggeredRow(
                start: 0.0,
                end: 0.3,
                child: Text(
                  'But the good news is',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: const Color(0xFFB08A5A), fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 6),
              _staggeredRow(
                start: 0.15,
                end: 0.5,
                child: Text(
                  "We'll help you stick to\nyour goal and get back",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: const Color(0xFF4A3728), fontSize: 22, fontWeight: FontWeight.w800, height: 1.3),
                ),
              ),
              const SizedBox(height: 28),
              _staggeredRow(
                start: 0.4,
                end: 0.6,
                child: SlotMachineYears(
                  value: _yearsReclaimed,
                  color: const Color(0xFF22C58B), // 👈 was #34C759 — saturated mint-green, closer to your app's accent family
                  startDelay: const Duration(milliseconds: 1200), // 👈 new — 0.4 * 3000ms
                ),
              ),
              const SizedBox(height: 28),
              _staggeredRow(
                start: 0.65,
                end: 0.85,
                child: Text(
                  'of your life',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: const Color(0xFF4A3728), fontSize: 20, fontWeight: FontWeight.w800, height: 1.3),
                ),
              ),
              const Spacer(flex: 4),
              _staggeredRow(
                start: 0.85,
                end: 1.0,
                child: OnboardingContinueButton(
                  label: 'Get those years back!',
                  onTap: widget.onContinue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}