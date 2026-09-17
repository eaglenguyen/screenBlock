// lib/onboarding_new/screens/onboarding_single_choice_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pausenow/onboarding_new/widget/typewriter_title.dart';

import 'option_pill.dart';
import 'progress_bar.dart';

class OnboardingSingleChoiceScreen extends StatefulWidget {
  final String title;
  final TextAlign titleAlign; // 👈 new
  final String? subtitle;
  final List<String> options;
  final List<IconData>? optionIcons;
  final String? otherLabel;
  final int progressStep;
  final int progressTotal;
  final VoidCallback onBack;
  final ValueChanged<String> onSelected;
  final String? infoImageAsset;

  const OnboardingSingleChoiceScreen({
    super.key,
    required this.title,
    this.titleAlign = TextAlign.left,
    this.subtitle,
    required this.options,
    this.optionIcons,
    this.otherLabel = 'Something else',
    required this.progressStep,
    required this.progressTotal,
    required this.onBack,
    required this.onSelected,
    this.infoImageAsset,
  });

  @override
  State<OnboardingSingleChoiceScreen> createState() => _OnboardingSingleChoiceScreenState();
}

class _OnboardingSingleChoiceScreenState extends State<OnboardingSingleChoiceScreen> {
  String? _selected;
  bool _hasChosen = false; // 👈 new


  void _showFullImage(BuildContext context, String asset) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Image.asset(asset),
                ),
              ),
              Positioned(
                top: 50,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _choose(String value) {
    if (_hasChosen) return; // 👈 new
    _hasChosen = true;
    setState(() => _selected = value);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) widget.onSelected(value);
    });
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
              TypewriterTitle(text: widget.title, textAlign: widget.titleAlign),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 10),
                Text(
                  widget.subtitle!,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFB08A5A),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              Expanded( // 👈 kept — but now wraps a scrollable column, not a fixed-fill ListView
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int i = 0; i < widget.options.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12), // 👈 replicates ListView.separated's spacing
                        OnboardingOptionPill(
                          label: widget.options[i],
                          icon: widget.optionIcons != null && i < widget.optionIcons!.length ? widget.optionIcons![i] : null,
                          isSelected: _selected == widget.options[i],
                          onTap: () => _choose(widget.options[i]),
                        ),
                      ],
                      if (widget.otherLabel != null) // 👈 moved inside — now sits directly under the last pill
                        Center(
                          child: GestureDetector(
                            onTap: () => _choose(widget.otherLabel!),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                widget.otherLabel!,
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF4A3728),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (widget.infoImageAsset != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: GestureDetector(
                              onTap: () => _showFullImage(context, widget.infoImageAsset!),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  widget.infoImageAsset!,
                                  width: 180,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}