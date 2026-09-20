// lib/onboarding_new/screens/demo_comparison_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart'; // adjust to your actual path
import '../../UI/schedule/schedule_viewmodel.dart'; // adjust to your actual path
import '../widget/continue_button.dart';
import '../widget/progress_bar.dart';

class OnboardingDemoComparisonScreen extends ConsumerStatefulWidget {
  final String scheduleId;
  final int progressStep;
  final int progressTotal;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final TimeOfDay scheduleStart;
  final TimeOfDay scheduleEnd;
  final List<int> scheduleDays;
  final List<String> blockedApps;

  const OnboardingDemoComparisonScreen({
    super.key,
    required this.scheduleId,
    required this.progressStep,
    required this.progressTotal,
    required this.onBack,
    required this.onNext,
    required this.scheduleStart,
    required this.scheduleEnd,
    required this.scheduleDays,
    required this.blockedApps,
  });

  @override
  ConsumerState<OnboardingDemoComparisonScreen> createState() => _OnboardingDemoComparisonScreenState();
}

class _OnboardingDemoComparisonScreenState extends ConsumerState<OnboardingDemoComparisonScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _titleFade;
  late Animation<double> _cardFade;
  late Animation<double> _withoutBarGrow;
  late Animation<double> _withBarGrow;
  late Animation<double> _subtitleFade;
  late Animation<double> _buttonFade;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000));
    _titleFade = _interval(0.0, 0.15);
    _cardFade = _interval(0.15, 0.3);
    _withoutBarGrow = _interval(0.35, 0.6);
    _withBarGrow = _interval(0.55, 0.85);
    _subtitleFade = _interval(0.8, 0.95);
    _buttonFade = _interval(0.9, 1.0);
    _ctrl.forward();
  }

  Animation<double> _interval(double start, double end) {
    return CurvedAnimation(parent: _ctrl, curve: Interval(start, end, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _createScheduleAndContinue() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(scheduleViewModelProvider.notifier).saveSchedule(
        existingId: widget.scheduleId,
        name: 'Blocked Apps',
        startTime: _fmt(widget.scheduleStart),
        endTime: _fmt(widget.scheduleEnd),
        days: widget.scheduleDays,
        blockingType: AppConstants.blockingTypeSpecificApps,
        blockedApps: widget.blockedApps,
        allowedApps: const [],
      );
    } catch (e) {
      debugPrint('❌ demo schedule creation error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED), // 👈 was inside QBShell's dark theme
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
              const SizedBox(height: 24),
              AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) {
                  return Expanded( // 👈 back to Expanded — needed so Spacer can work within it
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FadeTransition(
                          opacity: _titleFade,
                          child: Text(
                            'Become 5x more productive with Spinbrek',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF4A3728),
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const Spacer(), // 👈 new — pushes the graph card toward vertical center
                        SizedBox(
                          height: 340,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5EFE4),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: FadeTransition(
                                          opacity: _cardFade,
                                          child: _buildCard(
                                            label: 'Without Spinbrek',
                                            heightFraction: 0.2 * _withoutBarGrow.value,
                                            valueLabel: '20%',
                                            filled: false,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: FadeTransition(
                                          opacity: _cardFade,
                                          child: _buildCard(
                                            label: 'With Spinbrek',
                                            heightFraction: 1.0 * _withBarGrow.value,
                                            valueLabel: '5x',
                                            filled: true,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FadeTransition(
                                  opacity: _subtitleFade,
                                  child: Text(
                                    'Spinbrek keeps you active and makes it easy.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(color: const Color(0xFFB08A5A), fontSize: 13, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(), // 👈 new — balances the space below, so the card sits centered between title and button
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20), // 👈 moved outside the AnimatedBuilder's Column — fixed gap before the button
              FadeTransition(
                opacity: _buttonFade,
                child: OnboardingContinueButton(
                  label: _isSaving ? 'Saving...' : 'Continue',
                  enabled: !_isSaving,
                  onTap: _createScheduleAndContinue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String label,
    required double heightFraction,
    required String valueLabel,
    required bool filled,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFF0E6D8), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF4A3728),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxHeight = constraints.maxHeight;
                  final maxFillRatio = filled ? 0.95 : 0.90; // 👈 was: const maxFillRatio = 0.4; — now separate per bar
                  final scaledFraction = (heightFraction.clamp(0.0, 1.0)) * maxFillRatio;
                  return Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        height: maxHeight * scaledFraction,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: filled ? const Color(0xFF7DD3B0) : const Color(0xFFB08A5A).withValues(alpha: 0.4), // 👈 gray-ish for "without", matching reference's muted gray bar
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(18),
                            bottomRight: Radius.circular(18),
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              valueLabel,
                              style: GoogleFonts.poppins(
                                color: filled ? const Color(0xFF0F4A32) : Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}