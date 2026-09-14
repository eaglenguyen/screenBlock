// lib/onboarding_new/widgets/onboarding_progress_bar.dart
import 'package:flutter/material.dart';

class OnboardingProgressBar extends StatelessWidget {
  final int step;
  final int total;

  const OnboardingProgressBar({super.key, required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final isActive = i < step;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            height: 5,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF7DD3B0) : const Color(0xFFF0E6D8),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}