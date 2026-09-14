// lib/onboarding_new/screens/name_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widget/continue_button.dart';
import '../widget/progress_bar.dart';
import '../widget/typewriter_title.dart'; // adjust to match your actual OnboardingContinueButton import path

class OnboardingNameScreen extends StatefulWidget {
  final int progressStep;
  final int progressTotal;
  final VoidCallback onBack;
  final ValueChanged<String> onContinue;

  const OnboardingNameScreen({
    super.key,
    required this.progressStep,
    required this.progressTotal,
    required this.onBack,
    required this.onContinue,
  });

  @override
  State<OnboardingNameScreen> createState() => _OnboardingNameScreenState();
}

class _OnboardingNameScreenState extends State<OnboardingNameScreen> {
  final _ctrl = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      setState(() => _hasText = _ctrl.text.trim().isNotEmpty);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
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
              const SizedBox(height: 40),
              TypewriterTitle(
                text: "What is your name?",
                textAlign: TextAlign.center,
                fontSize: 30,
              ),

              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _hasText ? const Color(0xFF2D7A54).withValues(alpha: 0.5) : const Color(0xFFF0E6D8),
                    width: _hasText ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: TextField(
                  controller: _ctrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF4A3728),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Your name...',
                    hintStyle: GoogleFonts.poppins(color: const Color(0xFFB08A5A), fontSize: 18),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  ),
                  onSubmitted: (_) {
                    if (_hasText) widget.onContinue(_ctrl.text.trim());
                  },
                ),
              ),
              const Spacer(),
              OnboardingContinueButton(
                label: 'Continue',
                enabled: _hasText,
                onTap: () => widget.onContinue(_ctrl.text.trim()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}