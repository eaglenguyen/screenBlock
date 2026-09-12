// lib/UI/home/widgets/home_tutorial_overlay.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class HomeTutorialStep {
  final String title;
  final GlobalKey targetKey;
  const HomeTutorialStep({required this.title, required this.targetKey});
}

class HomeTutorialOverlay {
  static void show(
      BuildContext context, {
        required List<HomeTutorialStep> steps,
        required VoidCallback onComplete,
      }) {
    int index = 0;
    final overlayState = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;

    void next() {
      if (index >= steps.length - 1) {
        entry.remove();
        onComplete();
      } else {
        index++;
        entry.markNeedsBuild();
      }
    }

    entry = OverlayEntry(
      builder: (_) => _TutorialStepView(
        key: ValueKey(index),
        step: steps[index],
        stepNumber: index + 1,
        totalSteps: steps.length,
        onOkay: next,
      ),
    );
    overlayState.insert(entry);
  }
}
class _TutorialStepView extends StatefulWidget {
  final HomeTutorialStep step;
  final int stepNumber;
  final int totalSteps;
  final VoidCallback onOkay;

  const _TutorialStepView({
    super.key,
    required this.step,
    required this.stepNumber,
    required this.totalSteps,
    required this.onOkay,
  });

  @override
  State<_TutorialStepView> createState() => _TutorialStepViewState();
}

class _TutorialStepViewState extends State<_TutorialStepView> with TickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _scale;
  late Animation<double> _fade;

  late AnimationController _glowController; // 👈 new — pulsing glow behind the button
  late AnimationController _shineController; // 👈 new — sweeping shine across the button

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutBack),
    );
    _fade = CurvedAnimation(parent: _entryController, curve: const Interval(0.0, 0.5, curve: Curves.easeOut));
    _entryController.forward();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _glowController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  Rect? _targetRect() {
    final ctx = widget.step.targetKey.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final rect = _targetRect();

    if (rect == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onOkay());
      return const SizedBox.shrink();
    }

    const padding = 10.0;
    final spotlightRect = Rect.fromLTRB(
      rect.left - padding,
      rect.top - padding,
      rect.right + padding,
      rect.bottom + padding,
    );

    const cardWidth = 200.0;
    const tailHeight = 12.0;
    const estCardHeight = 120.0;
    final spaceBelow = screenSize.height - spotlightRect.bottom;
    final placeBelow = spaceBelow > estCardHeight + tailHeight + 40;

    final cardTop = placeBelow
        ? spotlightRect.bottom + tailHeight
        : (spotlightRect.top - estCardHeight - tailHeight).clamp(40.0, screenSize.height);

    double cardLeft = spotlightRect.center.dx - cardWidth / 2;
    cardLeft = cardLeft.clamp(16.0, screenSize.width - cardWidth - 16);
    final tailCenterX = (spotlightRect.center.dx - cardLeft).clamp(24.0, cardWidth - 24.0);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: AnimatedBuilder( // 👈 was FadeTransition — now feeds alpha into the painter directly
              animation: _entryController,
              builder: (context, child) => CustomPaint(
                painter: _DimPainter(spotlightRect: spotlightRect, fadeValue: _fade.value),
                size: Size.infinite,
              ),
            ),
          ),
        ),
        Positioned(
          left: spotlightRect.left - 16,
          top: spotlightRect.top - 16,
          width: spotlightRect.width + 32,
          height: spotlightRect.height + 32,
          child: IgnorePointer(

          ),
        ),
        Positioned(
          left: spotlightRect.left,
          top: spotlightRect.top,
          width: spotlightRect.width,
          height: spotlightRect.height,
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(spotlightRect.height / 2),
              child: AnimatedBuilder(
                animation: Listenable.merge([_shineController, _entryController]), // 👈 merged so both drive this
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ShinePainter(progress: _shineController.value, fadeValue: _fade.value), // 👈 fade passed in
                    size: Size(spotlightRect.width, spotlightRect.height),
                  );
                },
              ),
            ),
          ),
        ),
        Positioned(
          top: cardTop,
          left: cardLeft,
          width: cardWidth,
          child: ScaleTransition(
            scale: _scale,
            alignment: placeBelow ? Alignment.topCenter : Alignment.bottomCenter,
            child: AnimatedBuilder( // 👈 was FadeTransition — same fix for the bubble's shadow-based painter
              animation: _entryController,
              builder: (context, child) => CustomPaint(
                painter: _BubblePainter(
                  color: AppColors.backgroundCard(context),
                  fadeValue: _fade.value, // 👈 new
                ),
                child: child,
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16, placeBelow ? 16 + tailHeight : 16, 16, placeBelow ? 16 : 16 + tailHeight, // 👈 was 20 all around
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.step.title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textPrimary(context),
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                        decoration: TextDecoration.none, // 👈 added
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: GestureDetector(
                        onTap: widget.onOkay,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundSubtle(context),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border(context), width: 0.5),
                          ),
                          child: const Center(
                            child: Text(
                              '👍',
                              style: TextStyle(fontSize: 22, decoration: TextDecoration.none),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DimPainter extends CustomPainter {
  final Rect spotlightRect;
  final double fadeValue; // 👈 new
  const _DimPainter({required this.spotlightRect, required this.fadeValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = spotlightRect.center;
    final radius = spotlightRect.longestSide * 0.9;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.black.withValues(alpha: 0.0),
          Colors.black.withValues(alpha: 0.7 * fadeValue), // 👈 fade baked into alpha
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 2.2));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _DimPainter old) =>
      old.spotlightRect != spotlightRect || old.fadeValue != fadeValue;
}

class _ShinePainter extends CustomPainter {
  final double progress;
  final double fadeValue; // 👈 new
  const _ShinePainter({required this.progress, required this.fadeValue});

  @override
  void paint(Canvas canvas, Size size) {
    final sweepWidth = size.width * 0.5;
    final travel = size.width + sweepWidth;
    final x = -sweepWidth + progress * travel;

    final rect = Rect.fromLTWH(x, 0, sweepWidth, size.height);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.55 * fadeValue), // 👈 fade baked in
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: const GradientRotation(0.5),
      ).createShader(rect);

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _ShinePainter old) =>
      old.progress != progress || old.fadeValue != fadeValue;
}

class _BubblePainter extends CustomPainter {
  final Color color;
  final double fadeValue;
  const _BubblePainter({
    required this.color,
    required this.fadeValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 24.0;
    final paint = Paint()
      ..color = color.withValues(alpha: color.a * fadeValue)
      ..style = PaintingStyle.fill;

    final bodyRect = Rect.fromLTWH(0, 0, size.width, size.height); // 👈 simple full rect, no tail carve-out
    final path = Path()..addRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(radius)));

    if (fadeValue > 0.01) {
      canvas.drawShadow(path, Colors.black.withValues(alpha: fadeValue), 8, false);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BubblePainter old) =>
      old.color != color || old.fadeValue != fadeValue;
}