// lib/featuress/wheel/widgets/wheel_painter.dart
import 'dart:math';
import 'package:flutter/material.dart';

class WheelPainter extends CustomPainter {
  final List<String> items;
  final double rotation;

  WheelPainter({required this.items, required this.rotation});

  static const _colors = [
    Color(0xFFEDB82A),
    Color(0xFF4ECDC4),
    Color(0xFFE74C3C),
    Color(0xFF9B59B6),
    Color(0xFF3498DB),
    Color(0xFF2ECC71),
    Color(0xFFFF8C00),
    Color(0xFF1ABC9C),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final sweepAngle = 2 * pi / items.length;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);

    for (int i = 0; i < items.length; i++) {
      final startAngle = -pi / 2 + i * sweepAngle;
      final color = _colors[i % _colors.length];

      final paint = Paint()..color = color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // segment border
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // label, rotated along the segment's centerline
      final labelAngle = startAngle + sweepAngle / 2;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(labelAngle);
      final textPainter = TextPainter(
        text: TextSpan(
          text: items[i],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      );
      textPainter.layout(maxWidth: radius * 0.65);
      textPainter.paint(
        canvas,
        Offset(radius * 0.32, -textPainter.height / 2),
      );
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(WheelPainter oldDelegate) =>
      oldDelegate.rotation != rotation || oldDelegate.items != items;
}