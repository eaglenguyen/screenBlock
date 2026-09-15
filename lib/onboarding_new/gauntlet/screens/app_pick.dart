import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widget/continue_button.dart';
import '../../widget/progress_bar.dart';
import '../../widget/typewriter_title.dart';

class OnboardingGauntletAppsIntroScreen extends StatelessWidget {
  final int progressStep;
  final int progressTotal;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  const OnboardingGauntletAppsIntroScreen({
    super.key,
    required this.progressStep,
    required this.progressTotal,
    required this.onBack,
    required this.onContinue,
  });

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
                    onTap: onBack,
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
                  Expanded(child: OnboardingProgressBar(step: progressStep, total: progressTotal)),
                ],
              ),
              const Spacer(),
              Center(child: Text('🎯', style: const TextStyle(fontSize: 64))),
              const SizedBox(height: 24),
              const TypewriterTitle(
                text: 'We can help you\nreduce that time!',
                textAlign: TextAlign.center,
                fontSize: 28,
              ),
              const SizedBox(height: 10),
              Text(
                'By blocking the apps that eat up your day. Pick one to start.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: const Color(0xFFB08A5A), fontSize: 15, height: 1.4),
              ),
              const Spacer(),
              OnboardingContinueButton(
                label: 'Pick an App',
                onTap: onContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}