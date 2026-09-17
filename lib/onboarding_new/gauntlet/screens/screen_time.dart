import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widget/continue_button.dart';
import '../../widget/progress_bar.dart';
import '../../widget/typewriter_title.dart';

class OnboardingScreenTimeGuessScreen extends StatefulWidget {
  final int progressStep;
  final int progressTotal;
  final VoidCallback onBack;
  final ValueChanged<double> onContinue;

  const OnboardingScreenTimeGuessScreen({
    super.key,
    required this.progressStep,
    required this.progressTotal,
    required this.onBack,
    required this.onContinue,
  });

  @override
  State<OnboardingScreenTimeGuessScreen> createState() => _OnboardingScreenTimeGuessScreenState();
}

class _OnboardingScreenTimeGuessScreenState extends State<OnboardingScreenTimeGuessScreen> {
  double _hours = 4;
  bool _wasAtMax = false; // 👈 new — tracks whether we already fired the heavy haptic for hitting 12


  String get _label {
    if (_hours >= 12) return '12h+'; // 👈 new
    return '${_hours.round()}h';
  }

  Color get _labelColor { // 👈 new
    if (_hours >= 12) return const Color(0xFFE74C3C); // red
    if (_hours >= 8) return const Color(0xFFE8703A); // orange, ramping toward urgency
    return const Color(0xFF4A3728); // normal
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
                  Expanded(
                    child: OnboardingProgressBar(step: widget.progressStep, total: widget.progressTotal),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const TypewriterTitle(text: 'How much time do you\nspend on your phone?'),
              const SizedBox(height: 10),
              Text(
                "Take an educated guess if you don't know",
                style: GoogleFonts.poppins(color: const Color(0xFFB08A5A), fontSize: 15, height: 1.4),
              ),
              const Spacer(),
              Center(
                child: AnimatedDefaultTextStyle( // 👈 new — smoothly animates the color transition
                  duration: const Duration(milliseconds: 200),
                  style: GoogleFonts.poppins(
                    color: _labelColor,
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                  ),
                  child: Text(_label),
                ),
              ),
              const SizedBox(height: 24),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: _hours >= 12 ? const Color(0xFFE74C3C) : const Color(0xFF7DD3B0), // 👈 was #7FB4E8 blue — now mint accent
                  inactiveTrackColor: const Color(0xFFF0E6D8),
                  thumbColor: _hours >= 12 ? const Color(0xFFE74C3C) : const Color(0xFF7DD3B0), // 👈 was #7FB4E8
                  overlayColor: (_hours >= 12 ? const Color(0xFFE74C3C) : const Color(0xFF7DD3B0)).withValues(alpha: 0.2), // 👈 was #7FB4E8
                  trackHeight: 8,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
                ),
                child: Slider(
                  value: _hours,
                  min: 1,
                  max: 12,
                  divisions: 11,
                  onChanged: (v) {
                    final atMax = v >= 12;
                    if (atMax && !_wasAtMax) {
                      HapticFeedback.heavyImpact(); // 👈 new — fires once, right when it first reaches 12
                    } else if (!atMax) {
                      HapticFeedback.selectionClick(); // 👈 unchanged for every other value
                    }
                    _wasAtMax = atMax;
                    setState(() => _hours = v);
                  },
                ),
              ),
              const Spacer(),
              OnboardingContinueButton(
                label: 'Continue',
                onTap: () => widget.onContinue(_hours),
              ),
            ],
          ),
        ),
      ),
    );
  }
}