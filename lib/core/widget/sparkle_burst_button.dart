import 'dart:math';
import 'package:flutter/material.dart';

class SparkleBurstButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final List<Color> sparkleColors;
  final int sparkleCount;
  final double burstRadius;

  const SparkleBurstButton({
    super.key,
    required this.child,
    this.onTap,
    this.sparkleColors = const [
      Color(0xFFFF6B9D),
      Color(0xFFFFB84D),
      Color(0xFF7B4FE0),
      Color(0xFF4ECDC4),
      Color(0xFFFFD93D),
    ],
    this.sparkleCount = 8,
    this.burstRadius = 30,
  });

  @override
  State<SparkleBurstButton> createState() => SparkleBurstButtonState();
}

class SparkleBurstButtonState extends State<SparkleBurstButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = Random();
  List<_SparkleData> _sparkles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 👇 public — lets a parent trigger the burst programmatically (e.g. an auto-play loop),
  // not just via direct taps
  void fire() {
    setState(() {
      _sparkles = List.generate(widget.sparkleCount, (i) {
        final angle = (i / widget.sparkleCount) * 2 * pi + _random.nextDouble() * 0.4;
        final distance = widget.burstRadius * 0.8 + _random.nextDouble() * (widget.burstRadius * 0.4);
        return _SparkleData(
          angle: angle,
          distance: distance,
          size: 8 + _random.nextDouble() * 6,
          color: widget.sparkleColors[_random.nextInt(widget.sparkleColors.length)],
        );
      });
    });
    _controller.forward(from: 0);
  }

  void _handleTap() {
    fire();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              return Stack(
                alignment: Alignment.center,
                children: _sparkles.map((s) {
                  final dx = cos(s.angle) * s.distance * t;
                  final dy = sin(s.angle) * s.distance * t;
                  final opacity = (1 - t).clamp(0.0, 1.0);
                  final scale = (1 - t * 0.4).clamp(0.0, 1.0);
                  return Transform.translate(
                    offset: Offset(dx, dy),
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale,
                        child: Icon(Icons.auto_awesome_rounded, size: s.size, color: s.color),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _SparkleData {
  final double angle;
  final double distance;
  final double size;
  final Color color;
  const _SparkleData({required this.angle, required this.distance, required this.size, required this.color});
}