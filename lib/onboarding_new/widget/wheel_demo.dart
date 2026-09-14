// lib/onboarding_new/widgets/mini_wheel_preview.dart
import 'dart:math';
import 'package:flutter/material.dart';

class MiniWheelPreview extends StatefulWidget {
  const MiniWheelPreview({super.key});

  @override
  State<MiniWheelPreview> createState() => _MiniWheelPreviewState();
}

class _MiniWheelPreviewState extends State<MiniWheelPreview> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;
  double _currentRotation = 0;
  String _landedTask = '';
  final _random = Random();

  static const _tasks = ['Read', 'Clean', 'Walk', 'Journal', 'Stretch', 'Tidy'];
  static const _colors = [
    Color(0xFFEE8FA8),
    Color(0xFF7FB4E8),
    Color(0xFFEDA574),
    Color(0xFFB398E8),
    Color(0xFF7DD3B0),
    Color(0xFFF8D35A),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    _runCycle();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runCycle() async {
    while (mounted) {
      final segmentAngle = 2 * pi / _tasks.length;
      final fullSpins = 3 + _random.nextInt(2);
      final randomOffset = _random.nextDouble() * 2 * pi;
      final target = _currentRotation + fullSpins * 2 * pi + randomOffset;

      _rotation = Tween<double>(begin: _currentRotation, end: target).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
      );

      _controller.reset();
      await _controller.forward();
      if (!mounted) return;

      _currentRotation = target % (2 * pi);
      final normalized = (2 * pi - (target % (2 * pi))) % (2 * pi);
      final index = (normalized / segmentAngle).floor().clamp(0, _tasks.length - 1);
      setState(() => _landedTask = _tasks[index]);

      await Future.delayed(const Duration(milliseconds: 1400)); // hold on the result
      if (!mounted) return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 88,
          height: 88,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final rotation = _controller.isAnimating ? _rotation.value : _currentRotation;
                  return Transform.rotate(
                    angle: rotation,
                    child: child,
                  );
                },
                child: CustomPaint(
                  size: const Size(84, 84),
                  painter: _MiniWheelPainter(tasks: _tasks, colors: _colors),
                ),
              ),
              Positioned(
                top: -4,
                child: CustomPaint(
                  size: const Size(14, 12),
                  painter: _PointerPainter(),
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF4A3728), width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _landedTask.isEmpty
              ? const SizedBox(height: 20, key: ValueKey('empty'))
              : Container(
            key: ValueKey(_landedTask),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF7DD3B0).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              _landedTask,
              style: const TextStyle(color: Color(0xFF2D7A54), fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniWheelPainter extends CustomPainter {
  final List<String> tasks;
  final List<Color> colors;
  const _MiniWheelPainter({required this.tasks, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweep = 2 * pi / tasks.length;

    for (int i = 0; i < tasks.length; i++) {
      final start = -pi / 2 + i * sweep;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        true,
        Paint()..color = colors[i % colors.length],
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        true,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniWheelPainter old) => false;
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF4A3728));
  }

  @override
  bool shouldRepaint(covariant _PointerPainter old) => false;
}