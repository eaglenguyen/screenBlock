import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widget/continue_button.dart';
import '../../widget/progress_bar.dart';
import '../../widget/typewriter_title.dart';
import '../gauntlet_stones.dart';
import '../schedule_gauntlet_state.dart';




class OnboardingGauntletIntroScreen extends StatelessWidget {
  final int progressStep;
  final int progressTotal;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  const OnboardingGauntletIntroScreen({
    super.key,
    required this.progressStep,
    required this.progressTotal,
    required this.onBack,
    required this.onContinue,
  });

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
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: OnboardingProgressBar(step: progressStep, total: progressTotal)),
                ],
              ),
              const Spacer(),
              TypewriterTitle(
                text: "Block your apps with schedule sessions in\n4 easy steps!",
                textAlign: TextAlign.center,
                fontSize: 26,
                highlightWords: const {
                  'schedule sessions': Color(0xFF2D7A54), // 👈 accent green highlight
                },
              ),
              const SizedBox(height: 28),
              _buildEmptySlot(), // 👈 inline method instead of a separate widget/file
              const SizedBox(height: 32),
              ScheduleGauntletStones(
                state: ScheduleGauntletState(),
                justFilled: null,
              ),
              const Spacer(),
              OnboardingContinueButton(
                label: "Let's Go",
                onTap: onContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySlot() {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: const SizedBox(
        width: double.infinity,
        height: 60, // 👈 gives it a visible height since there's no content to size it anymore
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(20),
    );
    final path = Path()..addRRect(rrect);

    final paint = Paint()
      ..color = const Color(0xFFD9C7B0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const dashWidth = 6.0;
    const dashSpace = 5.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) => false;
}