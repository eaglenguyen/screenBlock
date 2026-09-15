import 'package:flutter/material.dart';
import 'progress_bar.dart';

class OnboardingShell extends StatelessWidget {
  final Widget child;
  final int? progressStep; // 👈 was double? progress
  final int? progressTotal; // 👈 new
  final VoidCallback? onBack;

  const OnboardingShell({
    super.key,
    required this.child,
    this.progressStep,
    this.progressTotal,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  if (onBack != null)
                    GestureDetector(
                      onTap: onBack,
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
                    )
                  else
                    const SizedBox(width: 38),
                  const SizedBox(width: 12),
                  if (progressStep != null && progressTotal != null)
                    Expanded(
                      child: OnboardingProgressBar(step: progressStep!, total: progressTotal!),
                    )
                  else
                    const Expanded(child: SizedBox()),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}