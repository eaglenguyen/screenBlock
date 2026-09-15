// lib/onboarding_new/screens/name_screen.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widget/continue_button.dart';
import '../widget/progress_bar.dart';
import '../widget/typewriter_title.dart'; // adjust to match your actual OnboardingContinueButton import path

class OnboardingNameScreen extends StatefulWidget {
  final int progressStep;
  final int progressTotal;
  final VoidCallback onBack;
  final ValueChanged<String> onContinue;
  final String title; // 👈 new
  final String subtitle; // 👈 new
  final String hint; // 👈 new
  final String continueLabel; // 👈 new
  final bool showRandomizer; // 👈 new

  const OnboardingNameScreen({
    super.key,
    required this.progressStep,
    required this.progressTotal,
    required this.onBack,
    required this.onContinue,
    this.title = "What should we\ncall you?", // 👈 keeps old default
    this.subtitle = "This is how we'll address you throughout the app.",
    this.hint = 'Your name...',
    this.continueLabel = 'Continue',
    this.showRandomizer = false, // 👈 new

  });

  @override
  State<OnboardingNameScreen> createState() => _OnboardingNameScreenState();
}

class _OnboardingNameScreenState extends State<OnboardingNameScreen> {
  final _ctrl = TextEditingController();
  bool _hasText = false;

  static const _randomNames = [ // 👈 new
    'Focus Fortress',
    'Deep Work Den',
    'No Distraction Zone',
    'The Grind Hour',
    'Locked In Mode',
    'Clarity Block',
    'Zen Hours',
    'Productivity Vault',
    'Flow State',
    'Quiet Hours',
    'Brain Sanctuary',
    'The Focus Zone',
  ];

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

  void _randomize() { // 👈 new
    HapticFeedback.selectionClick();
    final random = _randomNames[Random().nextInt(_randomNames.length)];
    _ctrl.text = random;
    _ctrl.selection = TextSelection.fromPosition(TextPosition(offset: _ctrl.text.length));
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
              TypewriterTitle(text: widget.title),
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
                    hintText: '',
                    hintStyle: GoogleFonts.poppins(color: const Color(0xFFB08A5A), fontSize: 18),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  ),
                  onSubmitted: (_) {
                    if (_hasText) widget.onContinue(_ctrl.text.trim());
                  },
                ),
              ),
              if (widget.showRandomizer) ...[ // 👈 new
                const SizedBox(height: 14),
                Center(
                  child: GestureDetector(
                    onTap: _randomize,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: const Color(0xFFF0E6D8), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🎲', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(
                            'Random',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF4A3728),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              OnboardingContinueButton(
                label: widget.continueLabel, // 👈 fixed — was hardcoded 'Continue', now actually uses the override
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