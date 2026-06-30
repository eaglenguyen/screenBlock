import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductivityGraph extends StatefulWidget {
  const ProductivityGraph({super.key});

  @override
  State<ProductivityGraph> createState() => _ProductivityGraphState();
}

class _ProductivityGraphState extends State<ProductivityGraph>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 240, // 👈 increased from 220 for x-axis label room
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return CustomPaint(
                painter: _GraphPainter(progress: _animation.value),
                size: const Size(double.infinity, 240),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _GraphPainter extends CustomPainter {
  final double progress;

  _GraphPainter({required this.progress});

  static const _gold = Color(0xFFEDB82A);
  static const _gray = Color(0xFFB4B2A9);

  @override
  void paint(Canvas canvas, Size size) {
    final l = 40.0;
    final r = size.width - 16.0;
    final t = 16.0;
    final b = size.height - 36.0; // 👈 leave room for x-axis labels
    final h = b - t;
    final w = r - l;

    _drawGrid(canvas, size, l, r, t, b);
    _drawYAxisLabel(canvas, size, t, b);
    _drawGrayLine(canvas, l, r, t, b, w, h);
    _drawGoldLine(canvas, l, r, t, b, w, h);
    _drawXAxisLabels(canvas, l, r, b); // 👈 new
  }

  void _drawGrid(Canvas canvas, Size size, double l, double r, double t, double b) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 0.5;

    const steps = 4;
    for (int i = 0; i <= steps; i++) {
      final y = b - (b - t) * i / steps;
      canvas.drawLine(Offset(l, y), Offset(r, y), paint);
    }
  }

  void _drawYAxisLabel(Canvas canvas, Size size, double t, double b) {
    final tp = TextPainter(
      text: TextSpan(
        text: 'Productivity',
        style: GoogleFonts.poppins(
          color: Colors.white.withOpacity(0.4),
          fontSize: 12,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    final midY = (t + b) / 2;
    canvas.translate(10, midY + tp.width / 2);
    canvas.rotate(-3.14159 / 2);
    tp.paint(canvas, Offset.zero);
    canvas.restore();
  }

  void _drawXAxisLabels(Canvas canvas, double l, double r, double b) {
    // "Start" on the left
    final startTp = TextPainter(
      text: TextSpan(
        text: 'Start',
        style: GoogleFonts.poppins(
          color: _gold,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    startTp.paint(canvas, Offset(l, b + 6));

    // "2 months" on the right
    final endTp = TextPainter(
      text: TextSpan(
        text: 'in 2 months',
        style: GoogleFonts.poppins(
          color: _gold,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    endTp.paint(canvas, Offset(r - endTp.width, b + 6));
  }

  void _drawEndLabel(Canvas canvas, String text, Color color, Offset point,
      {bool above = true}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final dx = point.dx - tp.width + 4;
    final dy = above ? point.dy - tp.height - 8 : point.dy + 8;
    tp.paint(canvas, Offset(dx, dy));
  }

  void _drawGrayLine(
      Canvas canvas, double l, double r, double t, double b, double w, double h) {
    final startY = b - h * 0.03;
    final endY = b - h * 0.22;

    final fullPath = Path()
      ..moveTo(l, startY)
      ..cubicTo(
        l + w * 0.35, startY - h * 0.06,
        l + w * 0.65, startY - h * 0.14,
        r, endY,
      );

    final clipX = l + (r - l) * progress;

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, -9999, clipX, 9999));
    final fillPath = Path.from(fullPath)
      ..lineTo(r, b)
      ..lineTo(l, b)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_gray.withOpacity(0.12), _gray.withOpacity(0.0)],
      ).createShader(Rect.fromLTRB(l, t, r, b))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);
    canvas.restore();

    final strokePaint = Paint()
      ..color = _gray.withOpacity(0.7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(_clipPathToProgress(fullPath, progress, l, r), strokePaint);

    if (progress > 0.95) {
      _drawArrow(canvas, _gray.withOpacity(0.7), fullPath, 1.0 - 0.01, 1.0);
    }
  }

  void _drawGoldLine(
      Canvas canvas, double l, double r, double t, double b, double w, double h) {
    final startY = b - h * 0.03;
    final endY = t + h * 0.04;

    final fullPath = Path()
      ..moveTo(l, startY)
      ..cubicTo(
        l + w * 0.25, startY - h * 0.04,
        l + w * 0.50, startY - h * 0.28,
        l + w * 0.70, b - h * 0.55,
      )
      ..cubicTo(
        l + w * 0.82, b - h * 0.72,
        l + w * 0.92, b - h * 0.88,
        r, endY,
      );

    final metrics = fullPath.computeMetrics().first;
    final partial = metrics.extractPath(0, metrics.length * progress);
    final endTangent = metrics.getTangentForOffset(metrics.length * progress);
    final currentEnd = endTangent?.position ?? Offset(l, b);

    final fillPath = Path.from(partial)
      ..lineTo(currentEnd.dx, b)
      ..lineTo(l, b)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_gold.withOpacity(0.22), _gold.withOpacity(0.0)],
      ).createShader(Rect.fromLTRB(l, t, r, b))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = _gold
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(partial, strokePaint);

    if (progress > 0.95) {
      _drawArrow(canvas, _gold, fullPath, 1.0 - 0.01, 1.0);
      _drawEndLabel(canvas, 'with pause now', _gold, Offset(r + 20, endY + 97));
    }
  }

  Path _clipPathToProgress(Path full, double progress, double l, double r) {
    if (progress >= 1.0) return full;
    final clipX = l + (r - l) * progress;
    final clipRect = Rect.fromLTRB(0, -9999, clipX, 9999);
    return Path.combine(
        PathOperation.intersect, full, Path()..addRect(clipRect));
  }

  void _drawArrow(Canvas canvas, Color color, Path path, double t0, double t1) {
    final metrics = path.computeMetrics().first;
    final len = metrics.length;

    final tang1 = metrics.getTangentForOffset(len * t0);
    final tang2 = metrics.getTangentForOffset(len * t1);
    if (tang1 == null || tang2 == null) return;

    final tip = tang2.position;
    final angle = (tip - tang1.position).direction;
    const arrowSize = 8.0;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(tip.dx, tip.dy);
    canvas.rotate(angle);
    final arrowPath = Path()
      ..moveTo(0, 0)
      ..lineTo(-arrowSize, -arrowSize * 0.45)
      ..lineTo(-arrowSize * 0.6, 0)
      ..lineTo(-arrowSize, arrowSize * 0.45)
      ..close();
    canvas.drawPath(arrowPath, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GraphPainter old) => old.progress != progress;
}