import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingSpotlightOverlay extends StatefulWidget {
  final VoidCallback onNameSubmitted;
  final Function(String name) onNameSet;

  const OnboardingSpotlightOverlay({
    super.key,
    required this.onNameSubmitted,
    required this.onNameSet,
  });

  @override
  State<OnboardingSpotlightOverlay> createState() =>
      _OnboardingSpotlightOverlayState();
}

class _OnboardingSpotlightOverlayState
    extends State<OnboardingSpotlightOverlay>
    with TickerProviderStateMixin {

  late AnimationController _fadeController;
  late AnimationController _arrowController;
  late Animation<double> _fadeAnim;
  late Animation<double> _arrowAnim;
  late Animation<double> _pulseAnim;

  bool _dialogShown = false;
  bool _dismissed = false;

  // profile icon position — top right
  // these are approximate, adjusted after layout
  final double _iconRight = 20;
  final double _iconTop = 56;
  final double _iconSize = 40;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _arrowAnim = CurvedAnimation(
      parent: _arrowController,
      curve: Curves.easeInOut,
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _arrowController,
        curve: Curves.easeInOut,
      ),
    );

    // fade in overlay then start arrow animation
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _arrowController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _arrowController.dispose();
    super.dispose();
  }

  void _onIconTapped() {
    if (_dialogShown) return;
    _dialogShown = true;
    HapticFeedback.lightImpact();
    widget.onNameSet(''); // 👈 pass empty name, chat will ask
    _fadeController.reverse().then((_) {
      if (mounted) {
        setState(() => _dismissed = true);
        widget.onNameSubmitted();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final size = MediaQuery.of(context).size;

    // spotlight center — "Start Chat" Text
    final spotlightX = size.width - 60.0;  // right side
    final spotlightY = 80.0;               // top area below status bar

    return FadeTransition(
      opacity: _fadeAnim,
      child: Stack(
        children: [
          // dark overlay with spotlight cutout
          CustomPaint(
            size: size,
            painter: _SpotlightPainter(
              spotlightX: spotlightX,
              spotlightY: spotlightY,
              spotlightRadius: 52,
            ),
          ),

          // curved arrow + tap hint text
          AnimatedBuilder(
            animation: _arrowAnim,
            builder: (context, child) {
              return CustomPaint(
                size: size,
                painter: _ArrowPainter(
                  spotlightX: spotlightX,
                  spotlightY: spotlightY,
                  progress: _arrowAnim.value,
                ),
              );
            },
          ),

          // tap hint text
          Positioned(
            right: 80,
            top: 130,
            child: AnimatedBuilder(
              animation: _arrowAnim,
              builder: (_, __) => Opacity(
                opacity: 0.6 + (_arrowAnim.value * 0.4),
              ),
            ),
          ),

          // tappable profile icon in spotlight
          Positioned(
            top: 56,
            right: 16,
            child: GestureDetector(
              onTap: _onIconTapped,
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) => Transform.scale(
                  scale: _pulseAnim.value,
                  child: child,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDB82A).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFEDB82A),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEDB82A).withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    'Start Chat',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFEDB82A),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Spotlight painter ─────────────────────────────────
class _SpotlightPainter extends CustomPainter {
  final double spotlightX;
  final double spotlightY;
  final double spotlightRadius;

  const _SpotlightPainter({
    required this.spotlightX,
    required this.spotlightY,
    required this.spotlightRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.75);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
    // 👈 no cutout — just plain dark overlay
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) => false;
}

// ── Arrow painter ─────────────────────────────────────

class _ArrowPainter extends CustomPainter {
  final double spotlightX;
  final double spotlightY;
  final double progress;

  const _ArrowPainter({
    required this.spotlightX,
    required this.spotlightY,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6 + progress * 0.4)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // start below the icon, curve up to it
    final startX = spotlightX - 90;
    final startY = spotlightY + 100; // start lower
    final endX = spotlightX - 12;
    final endY = spotlightY + 38; // end near icon bottom

    // control point pulls the curve
    final cpX = spotlightX - 20;
    final cpY = spotlightY + 90;

    final path = Path()
      ..moveTo(startX, startY)
      ..quadraticBezierTo(cpX, cpY, endX, endY);

    canvas.drawPath(path, paint);
    _drawArrowhead(canvas, paint, endX, endY, cpX, cpY);
  }

  void _drawArrowhead(
      Canvas canvas,
      Paint paint,
      double endX,
      double endY,
      double cpX,
      double cpY,
      ) {
    // direction of arrow at end point
    final dx = endX - cpX;
    final dy = endY - cpY;
    final angle = math.atan2(dy, dx);
    const arrowLen = 10.0;
    const arrowAngle = 0.5;

    final p1 = Offset(
      endX - arrowLen * math.cos(angle - arrowAngle),
      endY - arrowLen * math.sin(angle - arrowAngle),
    );
    final p2 = Offset(
      endX - arrowLen * math.cos(angle + arrowAngle),
      endY - arrowLen * math.sin(angle + arrowAngle),
    );

    canvas.drawLine(Offset(endX, endY), p1, paint);
    canvas.drawLine(Offset(endX, endY), p2, paint);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.progress != progress;
}