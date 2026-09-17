// lib/onboarding_new/screens/set_multiple_schedules_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widget/continue_button.dart';
import '../widget/progress_bar.dart';

class OnboardingSetMultipleSchedulesScreen extends StatefulWidget {
  final int progressStep;
  final int progressTotal;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const OnboardingSetMultipleSchedulesScreen({
    super.key,
    required this.progressStep,
    required this.progressTotal,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<OnboardingSetMultipleSchedulesScreen> createState() => _OnboardingSetMultipleSchedulesScreenState();
}

class _OnboardingSetMultipleSchedulesScreenState extends State<OnboardingSetMultipleSchedulesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<Animation<double>> _rowFades;
  late List<Animation<Offset>> _rowSlides;
  late Animation<double> _checkFade;
  late Animation<double> _checkScale;

  final List<Map<String, String>> _mockSchedules = [
    {'name': 'Schedule 1', 'time': '6AM - 5PM'},
    {'name': 'Schedule 2', 'time': '10AM - 5PM'},
    {'name': 'Schedule 3', 'time': '9AM - 9PM'},
    {'name': 'Schedule 4', 'time': '11AM - 3PM'},
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));

    _rowFades = List.generate(4, (i) {
      final start = i * 0.15;
      final end = (start + 0.35).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Interval(start, end, curve: Curves.easeOut)),
      );
    });
    _rowSlides = List.generate(4, (i) {
      final start = i * 0.15;
      final end = (start + 0.35).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
        CurvedAnimation(parent: _ctrl, curve: Interval(start, end, curve: Curves.easeOutCubic)),
      );
    });

    _checkFade = CurvedAnimation(parent: _ctrl, curve: const Interval(0.75, 1.0, curve: Curves.easeOut));
    _checkScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.75, 1.0, curve: Curves.elasticOut)),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED), // 👈 was Color(0xFF16162A)
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
                        color: Colors.white, // 👈 was Colors.white.withValues(alpha: 0.06)
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF0E6D8), width: 1), // 👈 was white alpha
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF4A3728), size: 16), // 👈 was Colors.white
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: OnboardingProgressBar(step: widget.progressStep, total: widget.progressTotal)), // 👈 new — matches every other screen
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Set Multiple Schedules',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF4A3728), // 👈 was Colors.white
                  fontSize: 28, // 👈 was 30, slightly reduced given the added progress bar row
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white, // 👈 was Color(0xFF1E1E35)
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFF0E6D8), width: 1), // 👈 was white alpha
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)), // 👈 new
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...List.generate(_mockSchedules.length, (i) {
                              final schedule = _mockSchedules[i];
                              return FadeTransition(
                                opacity: _rowFades[i],
                                child: SlideTransition(
                                  position: _rowSlides[i],
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                schedule['name']!,
                                                style: GoogleFonts.poppins(
                                                  color: const Color(0xFFB08A5A), // 👈 was Colors.white.withValues(alpha: 0.5)
                                                  fontSize: 11,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                schedule['time']!,
                                                style: GoogleFonts.poppins(
                                                  color: const Color(0xFF4A3728), // 👈 was Colors.white
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Transform.scale(
                                          scale: 0.75,
                                          child: Switch(
                                            value: true,
                                            onChanged: null,
                                            activeColor: const Color(0xFF7DD3B0), // 👈 was Color(0xFFEDB82A)
                                            activeTrackColor: const Color(0xFF7DD3B0).withValues(alpha: 0.4), // 👈 was gold alpha
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      FadeTransition(
                        opacity: _checkFade,
                        child: ScaleTransition(
                          scale: _checkScale,
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2D7A54), // 👈 was Color(0xFF4CAF50)
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded, color: Colors.white, size: 34),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Set as many blocking schedules & apps as you need. SpinBrek runs them all automatically, exactly when you need it.', // 👈 was "SpinBrek"
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: const Color(0xFFB08A5A), // 👈 was Colors.white.withValues(alpha: 0.45)
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              OnboardingContinueButton(label: 'Continue', onTap: widget.onNext), // 👈 was _ContinueButton
            ],
          ),
        ),
      ),
    );
  }
}