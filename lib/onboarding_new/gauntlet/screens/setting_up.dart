// lib/onboarding_new/screens/setting_up_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingSettingUpScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const OnboardingSettingUpScreen({
    super.key,
    required this.onContinue,
  });

  @override
  State<OnboardingSettingUpScreen> createState() => _OnboardingSettingUpScreenState();
}

class _OnboardingSettingUpScreenState extends State<OnboardingSettingUpScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;

  static const _checklist = [
    'Blocking your apps',
    'Setting your schedule',
    'Personalizing your wheel',
  ];

  static const _statuses = [
    'Getting things ready...',
    'Applying your schedule...',
    'Finalizing setup...',
  ];
  int _statusIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 5500));
    _progress = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.addListener(() {
      final newIndex = (_progress.value * _statuses.length).floor().clamp(0, _statuses.length - 1);
      if (newIndex != _statusIndex) {
        setState(() => _statusIndex = newIndex);
      }
    });

    _controller.forward().whenComplete(() {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) widget.onContinue();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isChecked(int index) {
    // each checklist item "checks off" once progress passes its share of the bar
    final threshold = (index + 1) / _checklist.length;
    return _progress.value >= threshold - 0.05;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "We're setting\neverything up for you",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF4A3728),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 32),
                AnimatedBuilder(
                  animation: _progress,
                  builder: (context, child) {
                    return Text(
                      '${(_progress.value * 100).round()}%',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF4A3728),
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                AnimatedBuilder(
                  animation: _progress,
                  builder: (context, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: LinearProgressIndicator(
                        value: _progress.value,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFF0E6D8),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7DD3B0)),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    _statuses[_statusIndex],
                    key: ValueKey(_statusIndex),
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFB08A5A),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                AnimatedBuilder(
                  animation: _progress,
                  builder: (context, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(_checklist.length, (i) {
                        final checked = _isChecked(i);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: checked ? 1.0 : 0.35,
                                child: Icon(
                                  checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                  color: checked ? const Color(0xFF2D7A54) : const Color(0xFFB08A5A),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: checked ? 1.0 : 0.5,
                                child: Text(
                                  _checklist[i],
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF4A3728),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}