// lib/onboarding_new/screens/bad_news_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widget/continue_button.dart';
import '../widget/slot_machine_animation.dart';

const Map<int, int> _screenTimeYearsPreset = {
  1: 3,
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


class OnboardingBadNewsScreen extends StatefulWidget {
  final double screenTimeHoursPerDay;
  final VoidCallback onContinue;

  const OnboardingBadNewsScreen({
    super.key,
    required this.screenTimeHoursPerDay,
    required this.onContinue,
  });

  @override
  State<OnboardingBadNewsScreen> createState() => _OnboardingBadNewsScreenState();
}

class _OnboardingBadNewsScreenState extends State<OnboardingBadNewsScreen> with TickerProviderStateMixin {
  late AnimationController _revealController;


  int get _finalYears {
    final hours = widget.screenTimeHoursPerDay.round().clamp(1, 12);
    return _screenTimeYearsPreset[hours] ?? 2;
  }

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000)); // 👈 was 1600 — slower overall
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
              _staggeredRow( // 👈 wider, more spread-out interval windows for a slower cascade
                start: 0.0,
                end: 0.25,
                child: Text(
                  'At this rate',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: const Color(0xFFB08A5A), fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 6),
              _staggeredRow(
                start: 0.2,   // 👈 was 0.15 — starts a bit later, less overlap with the row above
                end: 0.5,
                child: Text(
                  "You're going to spend",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: const Color(0xFF4A3728), fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 28),
              _staggeredRow(
                start: 0.45,  // 👈 was 0.35
                end: 0.65,    // 👈 was 0.55
                child: SlotMachineYears(
                  value: _finalYears,
                  color: const Color(0xFFE74C3C), // 👈 red
                  startDelay: const Duration(milliseconds: 1050), // 👈 new — 0.35 * 3000ms
                ),
              ),
              const SizedBox(height: 28),
              _staggeredRow(
                start: 0.7,   // 👈 was 0.6
                end: 0.95,    // 👈 was 0.85
                child: Text(
                  'of your life on\nyour phone',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: const Color(0xFF4A3728), fontSize: 20, fontWeight: FontWeight.w800, height: 1.3),
                ),
              ),
              const Spacer(flex: 4),
              _staggeredRow(
                start: 0.95,  // 👈 was 0.85
                end: 1.0,
                child: OnboardingContinueButton(
                  label: 'Wow.',
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