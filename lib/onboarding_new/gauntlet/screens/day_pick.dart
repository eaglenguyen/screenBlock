import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/lipped_button.dart';
import '../../widget/continue_button.dart';
import '../../widget/progress_bar.dart';
import '../../widget/typewriter_title.dart';

class OnboardingGauntletDaysScreen extends StatefulWidget {
  final int progressStep;
  final int progressTotal;
  final VoidCallback onBack;
  final ValueChanged<List<int>> onContinue;

  const OnboardingGauntletDaysScreen({
    super.key,
    required this.progressStep,
    required this.progressTotal,
    required this.onBack,
    required this.onContinue,
  });

  @override
  State<OnboardingGauntletDaysScreen> createState() => _OnboardingGauntletDaysScreenState();
}

class _OnboardingGauntletDaysScreenState extends State<OnboardingGauntletDaysScreen> {
  final Set<int> _selected = {0, 1, 2, 3, 4};
  static const _labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static const _weekdays = {0, 1, 2, 3, 4};
  static const _weekends = {5, 6};
  static const _everyday = {0, 1, 2, 3, 4, 5, 6};

  void _toggle(int i) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selected.contains(i)) {
        _selected.remove(i);
      } else {
        _selected.add(i);
      }
    });
  }

  void _selectPreset(Set<int> preset) {
    HapticFeedback.mediumImpact(); // 👈 bumped up — these are now the more prominent action
    setState(() {
      _selected
        ..clear()
        ..addAll(preset);
    });
  }

  bool _matchesPreset(Set<int> preset) =>
      _selected.length == preset.length && _selected.containsAll(preset);

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
              const TypewriterTitle(text: 'What days do you want\nthese apps blocked?'),
              const SizedBox(height: 24),
              Row( // 👈 bigger, 3D preset chips
                children: [
                  Expanded(child: _presetChip('Weekdays', _weekdays)),
                  const SizedBox(width: 10),
                  Expanded(child: _presetChip('Weekends', _weekends)),
                  const SizedBox(width: 10),
                  Expanded(child: _presetChip('Every day', _everyday)),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'or pick individual days',
                  style: TextStyle(color: const Color(0xFFB08A5A).withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 16),
              Wrap( // 👈 smaller, flat day pills — unchanged style, just visually secondary now
                spacing: 8,
                runSpacing: 8,
                children: List.generate(7, (i) {
                  final isSelected = _selected.contains(i);
                  return GestureDetector(
                    onTap: () => _toggle(i),
                    child: Container(
                      width: 76, // 👈 was 90 — smaller than before, to contrast with the bigger presets
                      padding: const EdgeInsets.symmetric(vertical: 12), // 👈 was 16
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFB398E8).withValues(alpha: 0.15) : Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF6A4FA0) : const Color(0xFFF0E6D8),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        _labels[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF6A4FA0) : const Color(0xFF4A3728),
                          fontWeight: FontWeight.w600, // 👈 was w700 — slightly lighter, secondary feel
                          fontSize: 13, // 👈 was 15
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const Spacer(),
              OnboardingContinueButton(
                label: 'Continue',
                enabled: _selected.isNotEmpty,
                onTap: () => widget.onContinue(_selected.toList()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _presetChip(String label, Set<int> days) {
    final isActive = _matchesPreset(days);
    return LippedButton( // 👈 was GestureDetector/Container — now 3D lipped
      onTap: () => _selectPreset(days),
      color: isActive ? const Color(0xFF7DD3B0) : Colors.white,
      lipColor: isActive ? const Color(0xFF2D7A54) : const Color(0xFFF0E6D8),
      height: 64, // 👈 bigger than the old chip's ~44px rendered height
      borderRadius: BorderRadius.circular(20),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isActive ? const Color(0xFF0F4A32) : const Color(0xFF4A3728),
          fontWeight: FontWeight.w800, // 👈 was w700 — bolder
          fontSize: 16, // 👈 was 13 — bigger
        ),
      ),
    );
  }
}