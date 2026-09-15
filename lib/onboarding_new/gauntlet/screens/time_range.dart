import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widget/progress_bar.dart';
import '../../widget/typewriter_title.dart';


class _TimePreset {
  final String label;
  final IconData icon; // 👈 was String emoji
  final String rangeLabel;
  final TimeOfDay start;
  final TimeOfDay end;

  const _TimePreset({
    required this.label,
    required this.icon,
    required this.rangeLabel,
    required this.start,
    required this.end,
  });
}

class OnboardingGauntletTimeRangeScreen extends StatefulWidget {
  final int progressStep;
  final int progressTotal;
  final VoidCallback onBack;
  final void Function(TimeOfDay start, TimeOfDay end) onContinue;

  const OnboardingGauntletTimeRangeScreen({
    super.key,
    required this.progressStep,
    required this.progressTotal,
    required this.onBack,
    required this.onContinue,
  });

  @override
  State<OnboardingGauntletTimeRangeScreen> createState() => _OnboardingGauntletTimeRangeScreenState();
}

class _OnboardingGauntletTimeRangeScreenState extends State<OnboardingGauntletTimeRangeScreen> {
  static const _presets = [
    _TimePreset(
      label: 'Morning Block',
      icon: Icons.wb_sunny_outlined, // 👈 was emoji: '🌅'
      rangeLabel: '6:00 AM - 12:00 PM',
      start: TimeOfDay(hour: 6, minute: 0),
      end: TimeOfDay(hour: 12, minute: 0),
    ),
    _TimePreset(
      label: 'Work Block',
      icon: Icons.work_outline_rounded, // 👈 was emoji: '💼'
      rangeLabel: '9:00 AM - 5:00 PM',
      start: TimeOfDay(hour: 9, minute: 0),
      end: TimeOfDay(hour: 17, minute: 0),
    ),
    _TimePreset(
      label: 'Night Block',
      icon: Icons.nightlight_outlined, // 👈 was emoji: '🌙'
      rangeLabel: '8:00 PM - 11:00 PM',
      start: TimeOfDay(hour: 20, minute: 0),
      end: TimeOfDay(hour: 23, minute: 0),
    ),
  ];

  int? _selectedIndex;

  void _select(int index) {
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        final preset = _presets[index];
        widget.onContinue(preset.start, preset.end);
      }
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
                  Expanded(child: OnboardingProgressBar(step: widget.progressStep, total: widget.progressTotal)),
                ],
              ),
              const SizedBox(height: 32),
              const TypewriterTitle(text: 'When should your\napps be blocked?'),
              const SizedBox(height: 10),
              Text(
                'Pick the time of day that fits your routine.',
                style: GoogleFonts.poppins(color: const Color(0xFFB08A5A), fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 32),
              ...List.generate(_presets.length, (i) {
                final preset = _presets[i];
                final isSelected = _selectedIndex == i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: GestureDetector(
                    onTap: () => _select(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF7DD3B0).withValues(alpha: 0.15) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF2D7A54) : const Color(0xFFF0E6D8),
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          SizedBox( // 👈 new — fixed box so the icon aligns predictably regardless of its natural size
                            width: 32,
                            height: 32,
                            child: Icon(preset.icon, size: 28, color: const Color(0xFFB08A5A)),
                          ),
                          const SizedBox(width: 14), // 👈 fixed — now on its own line
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  preset.label,
                                  style: GoogleFonts.poppins(
                                    color: isSelected ? const Color(0xFF2D7A54) : const Color(0xFF4A3728),
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  preset.rangeLabel,
                                  style: GoogleFonts.poppins(color: const Color(0xFFB08A5A), fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF2D7A54), size: 24),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}