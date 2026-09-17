// lib/onboarding_new/screens/setup_intro_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widget/continue_button.dart';
import '../widget/progress_bar.dart';
import '../widget/typewriter_title.dart';

class OnboardingSetupIntroScreen extends StatefulWidget {
  final String? userName;
  final int progressStep;
  final int progressTotal;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  const OnboardingSetupIntroScreen({
    super.key,
    this.userName,
    required this.progressStep,
    required this.progressTotal,
    required this.onBack,
    required this.onContinue,
  });

  @override
  State<OnboardingSetupIntroScreen> createState() => _OnboardingSetupIntroScreenState();
}

class _OnboardingSetupIntroScreenState extends State<OnboardingSetupIntroScreen> with SingleTickerProviderStateMixin {
  late AnimationController _revealController;
  bool _showTitle = false; // 👈 new

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(vsync: this, duration: const Duration(milliseconds: 6000));
    _revealController.forward();

    Future.delayed(Duration(milliseconds: (6000 * 0.3).round()), () { // 👈 new — matches the title's start:0.3 window
      if (mounted) setState(() => _showTitle = true);
    });
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  Widget _staggeredFade({required Widget child, required double start, required double end}) {
    final fade = CurvedAnimation(
      parent: _revealController,
      curve: Interval(start, end, curve: const Cubic(0.16, 1, 0.3, 1)), // 👈 a slower "ease-out-expo"-style curve — very gentle tail
    );
    final slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(fade);
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
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: widget.onBack,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF0E6D8), width: 1),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF4A3728), size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: OnboardingProgressBar(step: widget.progressStep, total: widget.progressTotal)),
                ],
              ),
              const Spacer(flex: 1),
              _staggeredFade( // 👈 text comes first now
                start: 0.0,
                end: 0.5,
                child: Text(
                  "Let's set things up",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFB08A5A),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _staggeredFade(
                start: 0.3,
                end: 0.75,
                child: SizedBox(
                  height: 96,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: _showTitle // 👈 new — TypewriterTitle doesn't exist in the tree (and can't fire haptics) until this flips true
                        ? TypewriterTitle(
                      text: '${widget.userName ?? "Hey"}, time to block some apps and take back your time!',
                      textAlign: TextAlign.center,
                      fontSize: 24,
                      startDelay: Duration.zero, // 👈 new — no need for its own internal delay anymore, the outer timer already handled that
                    )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _staggeredFade( // 👈 image animates in last
                start: 0.5,
                end: 0.9,
                child: Center(
                  child: Image.asset(
                    'assets/images/breakphone_smoothed.png',
                    height: 300,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const Spacer(flex: 2),
              OnboardingContinueButton(
                label: 'Continue',
                onTap: widget.onContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}