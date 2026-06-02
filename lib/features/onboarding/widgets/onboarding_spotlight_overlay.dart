import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    _showNameDialog();
  }

  void _showNameDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1E1E35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: const Color(0xFFEDB82A).withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDB82A).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('👋', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'What is your name?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),
              // text field
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF252542),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF2A2A48),
                    width: 0.5,
                  ),
                ),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Enter your name...',
                    hintStyle: TextStyle(
                      color: Color(0xFF7070A0),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: (_) => _submitName(controller.text, ctx),
                ),
              ),
              const SizedBox(height: 16),
              // submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _submitName(controller.text, ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEDB82A),
                    foregroundColor: const Color(0xFF1A1208),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text("Let's go →"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitName(String name, BuildContext dialogContext) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    HapticFeedback.mediumImpact();
    Navigator.of(dialogContext).pop();

    // tell parent the name
    widget.onNameSet(trimmed);

    // fade out overlay then start chat
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

    // spotlight center — profile icon position
    final spotlightX = size.width - _iconRight - (_iconSize / 2);
    final spotlightY = _iconTop + (_iconSize / 2);

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
              spotlightRadius: 36,
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
            right: 70,
            top: _iconTop + 60,
            child: AnimatedBuilder(
              animation: _arrowAnim,
              builder: (_, __) => Opacity(
                opacity: 0.6 + (_arrowAnim.value * 0.4),
                child: const Text(
                  'tap here!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ),

          // tappable profile icon in spotlight
          Positioned(
            right: _iconRight,
            top: _iconTop,
            child: GestureDetector(
              onTap: _onIconTapped,
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) => Transform.scale(
                  scale: _pulseAnim.value,
                  child: child,
                ),
                child: Container(
                  width: _iconSize,
                  height: _iconSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDB82A).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFEDB82A),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEDB82A).withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: Color(0xFFEDB82A),
                    size: 22,
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

    // draw full dark overlay
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // punch out spotlight circle using saveLayer + BlendMode
    canvas.saveLayer(fullRect, Paint());
    canvas.drawRect(fullRect, paint);

    // clear spotlight area
    final clearPaint = Paint()
      ..color = Colors.white
      ..blendMode = BlendMode.dstOut;

    canvas.drawCircle(
      Offset(spotlightX, spotlightY),
      spotlightRadius,
      clearPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.spotlightX != spotlightX ||
          old.spotlightY != spotlightY;
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