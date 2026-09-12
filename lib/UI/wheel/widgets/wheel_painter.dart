// lib/features/wheel/widgets/wheel_painter.dart
import 'dart:math';
import 'package:flutter/material.dart';

class WheelPainter extends CustomPainter {
  final List<String> items;
  final double rotation;
  final bool isDark; // 👈 new

  WheelPainter({required this.items, required this.rotation, required this.isDark});

  static const darkColors = [ // 👈 renamed from `colors` — unchanged, used for dark mode
    Color(0xFFF7C948),
    Color(0xFF2E9E8C),
    Color(0xFF7B4FE0),
    Color(0xFFE7527A),
    Color(0xFF3F8CE0),
    Color(0xFF52B788),
    Color(0xFFE8703A),
    Color(0xFF5A67D8),
  ];
  static const lightColors = [
    Color(0xFFF8D35A), // was FCE38A — deeper pastel gold
    Color(0xFF7FC9BB), // was A8DED3 — deeper pastel teal
    Color(0xFFB398E8), // was C8B6F0 — deeper pastel purple
    Color(0xFFEE8FA8), // was F3AFC0 — deeper pastel pink
    Color(0xFF7FB4E8), // was A9CDEE — deeper pastel blue
    Color(0xFF8ED2A4), // was AEDFC1 — deeper pastel green
    Color(0xFFEDA574), // was F3C0A0 — deeper pastel orange
    Color(0xFF97A2E8), // was B6BEEF — deeper pastel indigo
  ];

  static List<Color> colorsFor(bool isDark) => isDark ? darkColors : lightColors; // 👈 new — shared lookup for callers outside the painter

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;

    final palette = colorsFor(isDark); // 👈 new

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = min(size.width, size.height) / 2;
    final ringWidth = outerRadius * 0.045;
    final wheelRadius = outerRadius - ringWidth;
    final sweepAngle = 2 * pi / items.length;

    canvas.drawCircle(
      center,
      outerRadius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);

    for (int i = 0; i < items.length; i++) {
      final startAngle = -pi / 2 + i * sweepAngle;
      final color = palette[i % palette.length]; // 👈 was colors[...]

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: wheelRadius),
        startAngle,
        sweepAngle,
        true,
        Paint()..color = color,
      );

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: wheelRadius),
        startAngle,
        sweepAngle,
        true,
        Paint()
          ..shader = RadialGradient(
            colors: [Colors.white.withValues(alpha: 0.18), Colors.transparent],
            radius: 0.9,
          ).createShader(Rect.fromCircle(center: center, radius: wheelRadius)),
      );

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: wheelRadius),
        startAngle,
        sweepAngle,
        true,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );

      final labelAngle = startAngle + sweepAngle / 2;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(labelAngle);
      final textPainter = TextPainter(
        text: TextSpan(
          text: items[i],
          style: const TextStyle( // 👈 back to const, since it no longer varies
            color: Colors.white, // 👈 was isDark ? Colors.white : Color(0xFF4A4A4A) — now always white
            fontSize: 13,
            fontWeight: FontWeight.w800,
            shadows: [Shadow(color: Colors.black38, blurRadius: 2, offset: Offset(0, 1))], // 👈 back to the original dark shadow, since white text needs it for contrast on pastel fills too
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      );
      textPainter.layout(maxWidth: wheelRadius * 0.65);
      textPainter.paint(
        canvas,
        Offset(wheelRadius * 0.3, -textPainter.height / 2),
      );
      canvas.restore();
    }
    canvas.restore();

    canvas.drawCircle(
      center,
      outerRadius - ringWidth / 2,
      Paint()
        ..color = isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFFFFF6E5) // 👈 warm cream in light mode, unchanged white in dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth,
    );
  }

  @override
  bool shouldRepaint(WheelPainter oldDelegate) =>
      oldDelegate.rotation != rotation || oldDelegate.items != items || oldDelegate.isDark != isDark;
}