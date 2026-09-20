// lib/onboarding_new/screens/comparison_graph_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widget/continue_button.dart';
import '../widget/progress_bar.dart';
import '../widget/typewriter_title.dart';

class OnboardingComparisonGraphScreen extends StatefulWidget {
  final int progressStep;
  final int progressTotal;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  const OnboardingComparisonGraphScreen({
    super.key,
    required this.progressStep,
    required this.progressTotal,
    required this.onBack,
    required this.onContinue,
  });

  @override
  State<OnboardingComparisonGraphScreen> createState() => _OnboardingComparisonGraphScreenState();
}

class _OnboardingComparisonGraphScreenState extends State<OnboardingComparisonGraphScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _drawController;

  @override
  void initState() {
    super.initState();
    _drawController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _drawController.forward();
    });
  }

  @override
  void dispose() {
    _drawController.dispose();
    super.dispose();
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
              SizedBox( // 👈 new — reserves fixed space for the title, so its growth during typing doesn't shift anything below it
                height: 100, // 👈 tune this to roughly 2 lines' worth of height at your title's font size — adjust once you see it rendered
                child: Align(
                  alignment: Alignment.topLeft,
                  child: TypewriterTitle(text: 'Spinbrek replaces mindless scrolling with real action'),
                ),
              ),
              const SizedBox(height: 64),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF0E6D8), width: 1),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Time spent on phone',
                      style: GoogleFonts.poppins(color: const Color(0xFF4A3728), fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 20),
                    AnimatedBuilder(
                      animation: _drawController,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(double.infinity, 140),
                          painter: _ComparisonChartPainter(progress: _drawController.value),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Day 1', style: GoogleFonts.poppins(color: const Color(0xFFB08A5A), fontSize: 12)),
                        Text('Day 30', style: GoogleFonts.poppins(color: const Color(0xFFB08A5A), fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _legendDot(const Color(0xFFE74C3C)),
                        const SizedBox(width: 6),
                        Text('Without Spinbrek', style: GoogleFonts.poppins(color: const Color(0xFF4A3728), fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 20),
                        _legendDot(const Color(0xFF22C58B)),
                        const SizedBox(width: 6),
                        Text('With Spinbrek', style: GoogleFonts.poppins(color: const Color(0xFF4A3728), fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '84% of users report feeling more in control after just 2 weeks.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: const Color(0xFFB08A5A), fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              OnboardingContinueButton(
                label: 'Continue',
                onTap: widget.onContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 20,
      height: 3,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
    );
  }
}

class _ComparisonChartPainter extends CustomPainter {
  final double progress;
  const _ComparisonChartPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 👇 new — faint dotted horizontal gridlines, drawn first so curves render on top
    _drawDottedGridlines(canvas, w, h);

    // "Without SpinBrek" — rising curve (red)
    final withoutPath = Path();
    withoutPath.moveTo(0, h * 0.55);
    withoutPath.cubicTo(w * 0.25, h * 0.7, w * 0.35, h * 0.3, w * 0.55, h * 0.35);
    withoutPath.cubicTo(w * 0.75, h * 0.4, w * 0.85, h * 0.05, w, h * 0.02);

    // "With SpinBrek" — declining curve (green)
    final withPath = Path();
    withPath.moveTo(0, h * 0.15);
    withPath.cubicTo(w * 0.3, h * 0.1, w * 0.4, h * 0.55, w * 0.6, h * 0.6);
    withPath.cubicTo(w * 0.8, h * 0.65, w * 0.9, h * 0.92, w, h * 0.95);

    _drawAnimatedPath(canvas, withoutPath, const Color(0xFFE74C3C), progress);
    _drawAnimatedPath(canvas, withPath, const Color(0xFF22C58B), progress);

    final startEndPaint = Paint()..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(0, h * 0.15), 4, startEndPaint..color = const Color(0xFF22C58B));
    if (progress > 0.98) {
      canvas.drawCircle(Offset(w, h * 0.02), 4, startEndPaint..color = const Color(0xFFE74C3C));
      canvas.drawCircle(Offset(w, h * 0.95), 4, startEndPaint..color = const Color(0xFF22C58B));
    }
  }

  void _drawDottedGridlines(Canvas canvas, double w, double h) { // 👈 new
    final paint = Paint()
      ..color = const Color(0xFFF0E6D8)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const lineCount = 4; // number of horizontal gridlines
    const dashWidth = 4.0;
    const dashGap = 5.0;

    for (int i = 1; i <= lineCount; i++) {
      final y = h * (i / (lineCount + 1));
      double x = 0;
      while (x < w) {
        canvas.drawLine(Offset(x, y), Offset(x + dashWidth, y), paint);
        x += dashWidth + dashGap;
      }
    }
  }

  void _drawAnimatedPath(Canvas canvas, Path fullPath, Color color, double progress) {
    final metrics = fullPath.computeMetrics().toList();
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (final metric in metrics) {
      final extractLength = metric.length * progress.clamp(0.0, 1.0);
      final extractedPath = metric.extractPath(0, extractLength);
      canvas.drawPath(extractedPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ComparisonChartPainter old) => old.progress != progress;
}