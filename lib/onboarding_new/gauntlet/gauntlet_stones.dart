// lib/onboarding_new/widget/schedule_gauntlet_stones.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:pausenow/onboarding_new/gauntlet/schedule_gauntlet_state.dart';


class ScheduleGauntletStones extends StatefulWidget {
  final ScheduleGauntletState state;
  final ScheduleStone? justFilled;
  final bool isFinalStone; // 👈 new — tells the widget to play the celebration sound instead of the equip sound


  const ScheduleGauntletStones({
    super.key,
    required this.state,
    this.justFilled,
    this.isFinalStone = false,
  });

  @override
  State<ScheduleGauntletStones> createState() => _ScheduleGauntletStonesState();
}

class _ScheduleGauntletStonesState extends State<ScheduleGauntletStones> with TickerProviderStateMixin {
  late AnimationController _snapController;
  late AnimationController _sparkleController;
  late AnimationController _wobbleController;
  late AnimationController _trailController;
  late AnimationController _lineFillController; // 👈 new
  bool _sparkleTriggered = false;
  AudioPlayer? _equipPlayer;

  static const _stones = [ScheduleStone.apps, ScheduleStone.time, ScheduleStone.days, ScheduleStone.name];
  static const _colors = {
    ScheduleStone.name: Color(0xFFEE8FA8),
    ScheduleStone.time: Color(0xFF7FB4E8),
    ScheduleStone.apps: Color(0xFF7FC9BB),
    ScheduleStone.days: Color(0xFFB398E8),
  };

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _sparkleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _wobbleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _trailController = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _lineFillController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500)); // 👈 new

    if (widget.justFilled != null) {
      _equipPlayer = AudioPlayer();
      final soundAsset = widget.isFinalStone ? 'assets/sounds/confetti.mp3' : 'assets/sounds/equip.mp3'; // 👈 new
      _equipPlayer!.setAsset(soundAsset).catchError((e) {
        debugPrint('❌ equip sound load error: $e');
      });

      Future.delayed(const Duration(milliseconds: 200), () async {
        if (!mounted) return;
        _trailController.forward(from: 0);
        await _snapController.forward(from: 0);
        if (!mounted) return;

        try {
          _equipPlayer?.seek(Duration.zero);
          _equipPlayer?.play();
        } catch (e) {
          debugPrint('❌ equip sound play error: $e');
        }

        setState(() => _sparkleTriggered = true);
        _sparkleController.forward(from: 0);
        _wobbleController.forward(from: 0);
        _lineFillController.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    _snapController.dispose();
    _sparkleController.dispose();
    _wobbleController.dispose();
    _trailController.dispose();
    _lineFillController.dispose(); // 👈 new
    _equipPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_stones.length, (index) {
        final stone = _stones[index];
        final filled = widget.state.isFilled(stone);
        final isJustFilled = widget.justFilled == stone;
        final isLast = index == _stones.length - 1;

        return Row(
          children: [
            SizedBox(
              width: 60,
              height: 90,
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  if (!isJustFilled)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 28),
                      child: filled
                          ? _IdleShimmerStone(color: _colors[stone]!)
                          : _buildStone(filled: false, color: _colors[stone]!),
                    )
                  else ...[
                    AnimatedBuilder(
                      animation: _trailController,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(60, 90),
                          painter: _TrailDustPainter(progress: _trailController.value, color: _colors[stone]!),
                        );
                      },
                    ),
                    AnimatedBuilder(
                      animation: Listenable.merge([_snapController, _wobbleController]),
                      builder: (context, child) {
                        final snapT = Curves.easeOutBack.transform(_snapController.value);
                        final dy = (1 - snapT.clamp(0.0, 1.2)) * -140;
                        final scale = (0.5 + (0.5 * snapT)).clamp(0.0, 1.15);
                        final flightRotation = (1 - _snapController.value).clamp(0.0, 1.0) * 0.6;

                        double wobble = 0;
                        if (_snapController.isCompleted) {
                          final w = _wobbleController.value;
                          wobble = sin(w * pi * 4) * (1 - w) * 0.18;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 28),
                          child: Transform.translate(
                            offset: Offset(0, dy),
                            child: Transform.rotate(
                              angle: flightRotation + wobble,
                              child: Transform.scale(
                                scale: scale,
                                child: _buildStone(filled: true, color: _colors[stone]!),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  if (isJustFilled && _sparkleTriggered)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 28),
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _sparkleController,
                          builder: (context, child) => CustomPaint(
                            size: const Size(90, 90),
                            painter: _SparkleBurstPainter(
                              progress: _sparkleController.value,
                              color: _colors[stone]!,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (!isLast) // 👈 new — connector line between this gem and the next
              _buildConnectorLine(
                isFilling: isJustFilled,
                isAlreadyFilled: filled && !isJustFilled,
                color: _colors[stone]!,
              ),
          ],
        );
      }),
    );
  }

  Widget _buildConnectorLine({required bool isFilling, required bool isAlreadyFilled, required Color color}) { // 👈 new
    return Padding(
      padding: const EdgeInsets.only(bottom: 28), // aligns with the gem's vertical center, matching its own bottom padding
      child: SizedBox(
        width: 24,
        height: 4,
        child: isFilling
            ? AnimatedBuilder(
          animation: _lineFillController,
          builder: (context, child) {
            return _LineFill(progress: _lineFillController.value, color: color);
          },
        )
            : _LineFill(progress: isAlreadyFilled ? 1.0 : 0.0, color: color),
      ),
    );
  }

  Widget _buildStone({required bool filled, required Color color}) {
    return CustomPaint(
      size: const Size(34, 34),
      painter: _StonePainter(filled: filled, color: color),
    );
  }
}

class _LineFill extends StatelessWidget { // 👈 new
  final double progress;
  final Color color;
  const _LineFill({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFD9C7B0).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        FractionallySizedBox(
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }
}

// 👇 new — trailing dust particles behind the falling stone
class _TrailDustPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _TrailDustPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;
    final t = Curves.easeOutBack.transform(progress).clamp(0.0, 1.2);
    final currentY = size.height - 28 + ((1 - t) * -140) + 17; // matches the stone's travel path
    final centerX = size.width / 2;

    for (int i = 0; i < 5; i++) {
      final trailT = (progress - i * 0.06).clamp(0.0, 1.0);
      if (trailT <= 0) continue;
      final trailProgress = Curves.easeOutBack.transform(trailT).clamp(0.0, 1.2);
      final y = size.height - 28 + ((1 - trailProgress) * -140) + 17;
      final opacity = (1 - trailT) * 0.5 * (1 - progress);
      final dotSize = 3.0 - (i * 0.4);
      canvas.drawCircle(
        Offset(centerX + (i.isEven ? -4 : 4), y),
        dotSize.clamp(0.5, 3.0),
        Paint()..color = color.withValues(alpha: opacity.clamp(0.0, 1.0)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrailDustPainter old) => old.progress != progress;
}

// 👇 new — idle shimmer for already-equipped stones
class _IdleShimmerStone extends StatefulWidget {
  final Color color;
  const _IdleShimmerStone({required this.color});

  @override
  State<_IdleShimmerStone> createState() => _IdleShimmerStoneState();
}

class _IdleShimmerStoneState extends State<_IdleShimmerStone> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _loop();
  }

  Future<void> _loop() async {
    while (mounted) {
      await Future.delayed(Duration(milliseconds: 2000 + (widget.color.value % 1500)));
      if (!mounted) return;
      await _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(34, 34),
          painter: _StonePainter(filled: true, color: widget.color),
          foregroundPainter: _ShimmerSweepPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _ShimmerSweepPainter extends CustomPainter {
  final double progress;
  const _ShimmerSweepPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final w = size.width;
    final h = size.height;

    final outline = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w * 0.85, h * 0.28)
      ..lineTo(w * 0.72, h)
      ..lineTo(w * 0.28, h)
      ..lineTo(w * 0.15, h * 0.28)
      ..close();

    canvas.save();
    canvas.clipPath(outline);

    final sweepX = -w * 0.5 + (progress * w * 2);
    final rect = Rect.fromLTWH(sweepX, 0, w * 0.4, h);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.5),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ShimmerSweepPainter old) => old.progress != progress;
}

class _SparkleBurstPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _SparkleBurstPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;
    final center = Offset(size.width / 2, size.height / 2);
    const sparkleCount = 8;
    final eased = Curves.easeOut.transform(progress);
    final distance = eased * (size.width / 2 - 6);
    final opacity = (1 - progress).clamp(0.0, 1.0);

    for (int i = 0; i < sparkleCount; i++) {
      final angle = (2 * pi / sparkleCount) * i;
      final pos = center + Offset(cos(angle) * distance, sin(angle) * distance);
      final sparkleSize = (1 - progress) * 5 + 1;

      final paint = Paint()..color = color.withValues(alpha: opacity);
      // simple 4-point star / diamond sparkle
      final path = Path()
        ..moveTo(pos.dx, pos.dy - sparkleSize)
        ..lineTo(pos.dx + sparkleSize * 0.35, pos.dy - sparkleSize * 0.35)
        ..lineTo(pos.dx + sparkleSize, pos.dy)
        ..lineTo(pos.dx + sparkleSize * 0.35, pos.dy + sparkleSize * 0.35)
        ..lineTo(pos.dx, pos.dy + sparkleSize)
        ..lineTo(pos.dx - sparkleSize * 0.35, pos.dy + sparkleSize * 0.35)
        ..lineTo(pos.dx - sparkleSize, pos.dy)
        ..lineTo(pos.dx - sparkleSize * 0.35, pos.dy - sparkleSize * 0.35)
        ..close();
      canvas.drawPath(path, paint);
    }

    // small white flash at center on impact
    if (progress < 0.35) {
      final flashOpacity = (1 - (progress / 0.35)).clamp(0.0, 1.0);
      canvas.drawCircle(center, 14, Paint()..color = Colors.white.withValues(alpha: flashOpacity * 0.8));
    }
  }

  @override
  bool shouldRepaint(covariant _SparkleBurstPainter old) => old.progress != progress;
}

class _StonePainter extends CustomPainter {
  final bool filled;
  final Color color;
  const _StonePainter({required this.filled, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // gem outline: hexagonal-cut jewel shape (flat top, pointed bottom)
    final outline = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w * 0.85, h * 0.28)
      ..lineTo(w * 0.72, h)
      ..lineTo(w * 0.28, h)
      ..lineTo(w * 0.15, h * 0.28)
      ..close();

    if (!filled) {
      canvas.drawPath(
        outline,
        Paint()
          ..color = const Color(0xFFD9C7B0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      return;
    }

    // base gradient fill — lighter at top-left, deeper/richer toward bottom-right
    final baseGradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(color, Colors.white, 0.35)!,
          color,
          Color.lerp(color, Colors.black, 0.25)!,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(outline, baseGradient);

    canvas.save();
    canvas.clipPath(outline);

    // facet lines — radiating from the top point down to give a cut-gem look
    final facetPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawLine(Offset(w * 0.5, 0), Offset(w * 0.5, h), facetPaint);
    canvas.drawLine(Offset(w * 0.5, 0), Offset(w * 0.28, h), facetPaint);
    canvas.drawLine(Offset(w * 0.5, 0), Offset(w * 0.72, h), facetPaint);
    canvas.drawLine(Offset(w * 0.15, h * 0.28), Offset(w * 0.85, h * 0.28), facetPaint);

    // darker shading on the right-side facets for depth
    final shadeFacet = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w * 0.85, h * 0.28)
      ..lineTo(w * 0.72, h)
      ..lineTo(w * 0.5, h)
      ..close();
    canvas.drawPath(shadeFacet, Paint()..color = Colors.black.withValues(alpha: 0.12));

    // bright highlight streak on the top-left facet, like light catching the gem
    final highlight = Path()
      ..moveTo(w * 0.5, h * 0.05)
      ..lineTo(w * 0.32, h * 0.32)
      ..lineTo(w * 0.4, h * 0.32)
      ..lineTo(w * 0.5, h * 0.12)
      ..close();
    canvas.drawPath(highlight, Paint()..color = Colors.white.withValues(alpha: 0.55));

    // small sparkle dot near the top highlight
    canvas.drawCircle(Offset(w * 0.38, h * 0.18), 1.6, Paint()..color = Colors.white.withValues(alpha: 0.9));

    canvas.restore();

    // outer edge stroke for crisp definition
    canvas.drawPath(
      outline,
      Paint()
        ..color = Color.lerp(color, Colors.black, 0.35)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _StonePainter old) => old.filled != filled || old.color != color;
}