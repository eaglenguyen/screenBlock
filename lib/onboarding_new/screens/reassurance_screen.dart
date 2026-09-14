// lib/onboarding_new/screens/reassurance_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widget/continue_button.dart';
import '../widget/typewriter_title.dart';
import '../widget/wheel_demo.dart'; // adjust to match your actual file name/path for OnboardingContinueButton

class OnboardingReassuranceScreen extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback onBack; // 👈 new
  final String? userNeed; // 👈 new


  const OnboardingReassuranceScreen({
    super.key,
    required this.onContinue,
    required this.onBack, // 👈 new
    this.userNeed
  });

  static const _testimonials = [
    (name: 'Jamie R.', quote: 'I doomscrolled less for the first time in years. The wheel actually gets me doing things I keep putting off.'),
    (name: 'Alex T.', quote: "I used to freeze deciding what to do. Now I just spin and go — it's stupidly effective."),
    (name: 'Sam K.', quote: 'Cut my screen time in half in two weeks. Wish I found this sooner.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            children: [
              Row( // 👈 new — back button, matches the choice screens' pattern
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
                ],
              ),
              const SizedBox(height: 8), // 👈 new
              TypewriterTitle(
                text: "You're in the\nright place!",
                textAlign: TextAlign.center,
                fontSize: 30,
              ),
              const SizedBox(height: 24),
              const MiniWheelPreview(),
              const SizedBox(height: 12),

              Text(
                'SpinBrek helps our users to scroll less and live more productive lives.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: const Color(0xFFB08A5A),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: ListView.separated(
                  itemCount: _testimonials.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final t = _testimonials[i];
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFF0E6D8), width: 1),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(5, (_) => const Icon(Icons.star_rounded, color: Color(0xFFEDB82A), size: 16)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '"${t.quote}"',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF4A3728),
                              fontSize: 14,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '— ${t.name}',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFB08A5A),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              OnboardingContinueButton(
                label: 'CONTINUE',
                onTap: onContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}