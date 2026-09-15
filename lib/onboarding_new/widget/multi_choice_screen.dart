// lib/onboarding_new/screens/onboarding_multi_choice_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'continue_button.dart';
import 'option_pill.dart';
import 'progress_bar.dart';

class OnboardingMultiChoiceScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<String> options;
  final int progressStep;
  final int progressTotal;
  final VoidCallback onBack;
  final ValueChanged<List<String>> onContinue;

  const OnboardingMultiChoiceScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.options,
    required this.progressStep,
    required this.progressTotal,
    required this.onBack,
    required this.onContinue,
  });

  @override
  State<OnboardingMultiChoiceScreen> createState() => _OnboardingMultiChoiceScreenState();
}
class _OnboardingMultiChoiceScreenState extends State<OnboardingMultiChoiceScreen> {
  final Set<String> _selected = {};
  bool _hasChosen = false;

  void _toggle(String option) {
    if (_hasChosen) return; // 👈 new — locks selection once Continue has been tapped
    setState(() {
      if (_selected.contains(option)) {
        _selected.remove(option);
      } else {
        _selected.add(option);
      }
    });
  }

  void _handleContinue() { // 👈 new
    if (_hasChosen) return;
    _hasChosen = true;
    widget.onContinue(_selected.toList());
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _selected.isNotEmpty;

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
              Text(
                widget.title,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF4A3728),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.subtitle,
                style: GoogleFonts.poppins(
                  color: const Color(0xFFB08A5A),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: ListView.separated(
                  itemCount: widget.options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final option = widget.options[i];
                    return OnboardingOptionPill(
                      label: option,
                      isSelected: _selected.contains(option),
                      onTap: () => _toggle(option),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              OnboardingContinueButton(
                label: 'Continue',
                enabled: canContinue,
                onTap: _handleContinue, // 👈 was: () => widget.onContinue(_selected.toList())
              ),
            ],
          ),
        ),
      ),
    );
  }
}